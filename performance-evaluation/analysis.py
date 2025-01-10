import pandas as pd
import matplotlib.pyplot as plt
import os

# Function to process files and plot response times and failure percentages
def plot_metrics_from_folder(folder_path):
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
                    request_count = aggregated["Request Count"].values[0]
                    failure_count = aggregated["Failure Count"].values[0]

                    # Calculate failure percentage
                    failure_percentage = (failure_count / request_count) * 100 if request_count > 0 else 0

                    # Append data to the list
                    all_data.append({
                        "n": n,
                        "users": users,
                        "Average Response Time": avg_response_time,
                        "Max Response Time": max_response_time,
                        "Failure Percentage": failure_percentage
                    })

    if not all_data:
        print("Error: No data found in the folder.")
        return

    # Create a DataFrame from collected data
    data_df = pd.DataFrame(all_data)

    # Sort data for plotting
    data_df.sort_values(by=["users", "n"], ascending=[True, True], inplace=True)

    # Plot the data
    fig, ax1 = plt.subplots(figsize=(12, 8))

    # Plot response times on the primary y-axis
    ax1.plot(range(len(data_df)), data_df["Average Response Time"], marker='o', label="Average Response Time", color='blue')
    ax1.plot(range(len(data_df)), data_df["Max Response Time"], marker='o', label="Max Response Time", color='green')
    ax1.set_ylabel("Response Time (ms)")
    ax1.set_xlabel("Configuration (#vm-#users)")
    ax1.set_xticks(range(len(data_df)))
    ax1.set_xticklabels([f"{int(row['n'])}vm-{int(row['users'])}usr" for _, row in data_df.iterrows()], rotation=45)
    ax1.legend(loc="upper left")
    ax1.grid(True)

    # Add a secondary y-axis for failure percentage
    ax2 = ax1.twinx()
    ax2.plot(range(len(data_df)), data_df["Failure Percentage"], marker='o', label="Failure Percentage", color='red')
    ax2.set_ylabel("Failure Percentage (%)", color='red')
    ax2.tick_params(axis='y', labelcolor='red')
    ax2.legend(loc="upper right", fontsize=10, frameon=False)

    plt.title("Response Times and Failure Percentage Across Configurations")
    plt.tight_layout()
    plt.show()

# Specify the folder path
folder_path = "./performance-evaluation/results"
plot_metrics_from_folder(folder_path)
