import requests
import time

url = "http://alb-eks-1401051952.us-east-2.elb.amazonaws.com/tools.descartes.teastore.webui/"   # TODO ALWAYS ADJUST
limit = 500  
delay_seconds = 60 / limit  

headers = {
    "User-Agent": "My Test Script", 
}

for i in range(limit + 10):
    response = requests.get(url, headers=headers)
    print(f"Request {i + 1}: status code {response.status_code}")
    time.sleep(delay_seconds)  

print("Test completed.")