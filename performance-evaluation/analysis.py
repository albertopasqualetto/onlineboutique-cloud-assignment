import pandas as pd
import matplotlib.pyplot as plt
import os

# Function to process files
def plot_response_times_from_folder(folder_path):
    all_data = []

    # Scroll through all files in the folder
    for file_name in os.listdir(folder_path):
        if file_name.endswith("_stats.csv"):
           
            parts = file_name.split("vm")
            if len(parts) > 1 and ("usr" in parts[1] or "user" in parts[1]):
                n_part, users_part = parts[0], parts[1]
                n = int(n_part)
                
                # Handle both "usr" and "user" cases
                if "usr" in users_part:
                    users = int(users_part.split("usr")[0])
                elif "user" in users_part:
                    users = int(users_part.split("user")[0])

                file_path = os.path.join(folder_path, file_name)
                df = pd.read_csv(file_path)

                # Filter the row with "Name" == "Aggregated"
                aggregated = df[df["Name"] == "Aggregated"]

                if not aggregated.empty:
                    avg_response_time = aggregated["Average Response Time"].values[0]
                    max_response_time = aggregated["Max Response Time"].values[0]

                    # Append data to the list
                    all_data.append({
                        "n": n,
                        "users": users,
                        "Average Response Time": avg_response_time,
                        "Max Response Time": max_response_time
                    })

    if not all_data:
        print("Errore: Nessun dato trovato nella cartella.")
        return

    print(all_data)
    data_df = pd.DataFrame(all_data)
    print(data_df)

    # Sort data for plotting
    data_df.sort_values(by=["users", "n"], ascending=[True, True], inplace=True)

    # Plot the data
    plt.figure(figsize=(12, 8))
    plt.plot(range(len(data_df)), data_df["Average Response Time"], marker='o', label="Average Response Time")
    plt.plot(range(len(data_df)), data_df["Max Response Time"], marker='o', label="Max Response Time")
    plt.xticks(range(len(data_df)), [f"{row['n']}vm-{row['users']}usr" for _, row in data_df.iterrows()], rotation=45)
    plt.title("Response Times Across Multiple Configuration")
    plt.ylabel("Response Time (ms)")
    plt.xlabel("Configuration (#vm-#users)")
    plt.legend()
    plt.tight_layout()
    plt.show()

# Specify the folder path
folder_path = "./performance-evaluation/results"
plot_response_times_from_folder(folder_path)
