from locust import HttpUser, task, between

class FrontendUser(HttpUser):
    host = "http://<your-frontend-ip-or-domain>"
    # Tempo di attesa tra ogni task (simulazione di utenti)
    wait_time = between(1, 5)  # 1-5 secondi di attesa tra le richieste
    
    # Task che viene eseguito quando un utente invia una richiesta HTTP
    @task
    def index(self):
        # Sostituisci con l'IP pubblico o il dominio del tuo frontend
        self.client.get("/")

    # Task aggiuntivo per simulare l'accesso alla pagina di un prodotto
    @task(2)
    def product_page(self):
        # Simula la navigazione sulla pagina di un prodotto
        self.client.get("/product/1")
