# Customer Personality Segmentation (R)

## 📊 Project Overview

This project performs customer segmentation using the **Customer Personality Analysis** dataset. The primary goal is to identify patterns in customer behavior, demographics, and spending habits to segment customers into distinct groups. This segmentation can help businesses tailor their marketing strategies, enhance customer satisfaction, and deliver more targeted offers.

## 🧾 Dataset Description

Source: [Kaggle - Customer Personality Analysis](https://www.kaggle.com/datasets/imakash3011/customer-personality-analysis/data)

The dataset contains demographic and purchase behavior data for customers, including:

- **Demographics**: Age, Income, Education, Marital Status, Family Composition
- **Spending**: Amounts spent on various product categories (Wine, Meat, Fish, Gold, etc.)
- **Promotion Response**: Campaign acceptance (1st to 5th and last)
- **Channels**: Web, catalog, store purchases
- **Other**: Days since last purchase, complaints, etc.

## 🧹 Data Preprocessing & Feature Engineering

- **Handled Missing Values**: Dropped rows with missing income data (24 rows).
- **One-Hot Encoding**: Applied on categorical variables (Education, Marital Status) using `fastDummies` in R.
- **Derived Features**:
  - `Age = 2025 - Year_Birth`
  - `Family_Size = Adults (inferred) + Teenhome + Kidhome`
  - `Total_Spent = Sum of all product spending fields`

## 🧠 Methodology

### 🔶 K-Means Clustering (k=3)
Normalized selected features and applied KMeans:
- `Income`, `Age`, `Family_Size`, `Total_Spent`

![image](https://github.com/user-attachments/assets/09d7c530-cb70-4b56-abfc-ae9b3e5754bd)


**Cluster Summaries**:
- **Cluster 1**: High income, high spenders, small families (young professionals or couples)
- **Cluster 2**: Low income, low spenders, average family size (students or early-career individuals)
- **Cluster 3**: Moderate income, older age, larger families (mature households)

### 🔷 DBSCAN
Parameters: `eps = 0.25`, `minPts = 16`

Formed clusters without labeling noise. Highlights groups based on density of similar customer behaviors.
![image](https://github.com/user-attachments/assets/3cd87d7f-c112-4c9b-a721-6dc6d931bae2)
![image](https://github.com/user-attachments/assets/7a1daad3-da59-42d1-af15-84c2cdf49623)

### 🔸 Hierarchical Clustering
Used `cutree()` with `k=3` to form clusters from dendrogram.
- Sampled smaller datasets for better visual clarity.
- Revealed similar clusters as KMeans with good hierarchy representation.
![image](https://github.com/user-attachments/assets/2735279c-12bb-4949-882b-54a526fed071)
![image](https://github.com/user-attachments/assets/39215085-1372-44dd-a595-6bbc5689c842)

## 📈 Visualizations

- Boxplots for feature distribution per cluster (KMeans, DBSCAN)
- Dendrograms from hierarchical clustering
- Cluster scatter plots for exploratory analysis

![image](https://github.com/user-attachments/assets/69b3aa0a-b2bb-4577-95b0-12f89ca73fff)


## 🛠️ Technologies Used

- **Language**: R
- **Libraries**: `tidyverse`, `cluster`, `factoextra`, `fastDummies`, `ggplot2`, `dendextend`

## 📌 Key Takeaways

- KMeans and hierarchical clustering revealed 3 meaningful customer segments.
- Useful insights into high-value customers and budget-conscious groups.
- Ready-to-use model for developing targeted marketing strategies.

## 📬 Contact

For questions or collaboration, feel free to reach out!

**Shabbir Haque Akash**  
Data Science MSc. | SDU Denmark  
📧 shabbir.akash18@gmail.com  
🌐 https://www.linkedin.com/in/shabbir-haque
