import boto3
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def lambda_handler(event, context):
    # Get text from json in the request body
    release = event["queryStringParameters"]["release"]
    print(release)

    options = Options()
    options.binary_location = '/opt/headless-chromium'
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--single-process')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--windows-size=2560,1440')

    driver = webdriver.Chrome('/opt/chromedriver',chrome_options=options)
    
    driver.get('https://www.lambtoncollege.ca/programs/international/doct/')
    title = driver.title
    wait = WebDriverWait(driver, 10)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, 'body')))

    # find the input element and fill in some text
    # elem = driver.find_element(By.ID,"value")
    # elem.send_keys(release)

    # simulate hitting the enter key to submit the form
    # elem.send_keys(Keys.RETURN)
    # wait = WebDriverWait(driver, 3)
    
    # Take a screenshot and save it to /tmp/screenshot.png
    driver.save_screenshot('/tmp/home_'+release+'.png')
    
    s3 = boto3.client('s3')
    bucket_name = 'andyawson-ui-test'
    s3_key = 'screenshots/home_'+release+'.png'
    with open('/tmp/home_'+release+'.png', 'rb') as f:
        s3.upload_fileobj(f, bucket_name, s3_key)

    # elem = driver.find_elements(By.XPATH, "//button[text()='Delete']")
    # elem[len(elem)-1].click()

    driver.close()
    driver.quit()

    response = {
        "statusCode": 200,
        "body": "{\n" + f'"release":"{release}"'+" }"
    }

    return response