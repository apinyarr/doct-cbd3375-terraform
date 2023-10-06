import json
import boto3
import pickle
from io import BytesIO
import pandas as pd
from sklearn.naive_bayes import MultinomialNB
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer


# Prediction function from the model
def get_predicted_result(api_text, countvector, tfidf_transformer, loaded_lm):
    X_test_api = pd.Series({'clean_text': api_text})
    X_test_api = countvector.transform(X_test_api)
    X_test_api = tfidf_transformer.transform(X_test_api)
    
    return loaded_lm.predict(X_test_api)

# This function is for calling from lambda and return   
def get_bully_type(api_text, countvector, tfidf_transformer, loaded_lm):
    y_api_pred = get_predicted_result(api_text, countvector, tfidf_transformer, loaded_lm)
    map_types = ['age', 'ethnicity', 'gender', 'not_cyberbullying', 'other_cyberbullying', 'religion']
    return map_types[y_api_pred[0]]

def lambda_handler(event, context):
    # Get text from json in the request body
    text = json.loads(event['body'])['text']
    # Put file name of each objects we need for the prediction
    bucket = 'dataset-3375-2'
    file = 'cyberbullying_model.sav'
    countvector_file = 'countvector.sav'
    tfidf_transformer_file = 'tfidf_transformer.sav'
    
    try:
        # Get the object from S3
        s3 = boto3.resource('s3')
        with BytesIO() as data:
            s3.Bucket(bucket).download_fileobj(file, data)
            data.seek(0)    # move back to the beginning after writing
            loaded_lm = pickle.load(data)
        with BytesIO() as data:
            s3.Bucket(bucket).download_fileobj(countvector_file, data)
            data.seek(0)    # move back to the beginning after writing
            countvector = pickle.load(data)
        with BytesIO() as data:
            s3.Bucket(bucket).download_fileobj(tfidf_transformer_file, data)
            data.seek(0)    # move back to the beginning after writing
            tfidf_transformer = pickle.load(data)
        # Get the prediction result from model
        type_prediction = get_bully_type(text, countvector, tfidf_transformer, loaded_lm)
        if type_prediction != 'not_cyberbullying':
            result_prediction = 'true'
        else:
            result_prediction = 'false'
        # return "{ \n" + f'"result":"{result_prediction}"' + f'",\n\t"type":"{type_prediction}"\n' + " }"
        return {
            'body': { 
                "result": str(result_prediction),
                "type": str(type_prediction)
            },
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
                },
        }
    except Exception as e:
        print(e)
        print('error occurred')
        raise e

