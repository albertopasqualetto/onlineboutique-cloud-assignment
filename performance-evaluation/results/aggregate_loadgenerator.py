import pandas as pd
import os
from collections import defaultdict

def aggregate_files_in_folder(folder_path):
    aggregated_data = defaultdict(list)

    # Leggi tutti i file nella cartella
    for file_name in os.listdir(folder_path):
        # Verifica che il file corrisponda al formato desiderato
        if "_stats_" in file_name and "loadgenerator-" in file_name:
            parts = file_name.split("vm")
            if len(parts) > 1 and "users" in parts[1]:
                # Estrai [n] e [users] dalla configurazione
                n_part, users_part = parts[0], parts[1].split("_")[0]
                configuration = f"{n_part}vm{users_part}"

                file_path = os.path.join(folder_path, file_name)
                df = pd.read_csv(file_path)

                # Filtra la riga con il nome "Aggregated"
                aggregated = df[df["Name"] == "Aggregated"]

                if not aggregated.empty:
                    aggregated_data[configuration].append(aggregated)

    # Scrivi un file CSV per ogni configurazione
    for config, data_list in aggregated_data.items():
        # Combina i dati aggregati per ogni configurazione
        combined_df = pd.concat(data_list)

        # Aggrega i valori per ciascun campo
        aggregated_row = {
            "Type": "Aggregated",
            "Name": "Aggregated",
            "Request Count": combined_df["Request Count"].sum(),
            "Failure Count": combined_df["Failure Count"].sum(),
            "Median Response Time": combined_df["Median Response Time"].median(),
            "Average Response Time": combined_df["Average Response Time"].mean(),
            "Min Response Time": combined_df["Min Response Time"].min(),
            "Max Response Time": combined_df["Max Response Time"].max(),
            "Average Content Size": combined_df["Average Content Size"].mean(),
            "Requests/s": combined_df["Requests/s"].mean(),
            "Failures/s": combined_df["Failures/s"].mean(),
        }

        # Aggiungi i percentili (50%, 66%, 75%, ecc.)
        for percentile in ["50%", "66%", "75%", "80%", "90%", "95%", "98%", "99%", "99.9%", "99.99%", "100%"]:
            aggregated_row[percentile] = combined_df[percentile].median()

        # Crea un DataFrame per scrivere nel CSV
        final_df = pd.DataFrame([aggregated_row])

        # Salva il file
        output_file = os.path.join(folder_path, f"{config}_stats.csv")
        final_df.to_csv(output_file, index=False)

    print("Aggregazione completata e file salvati.")

# Specifica il percorso della cartella
folder_path = "./performance-evaluation/results"
aggregate_files_in_folder(folder_path)
