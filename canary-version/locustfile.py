from locust import HttpUser, task, between

class FrontendUser(HttpUser):
    host = "http://34.27.165.38"
    wait_time = between(1, 5) 
    
    @task
    def index(self):
        self.client.get("/")

    # Task
    @task(2)
    def product_page(self):
        self.client.get("/product/OLJCESPC7Z")
