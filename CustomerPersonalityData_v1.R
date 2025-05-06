library(dplyr)    
library(ggplot2)  
library(readr)
library(fastDummies)
library(factoextra)
library(ClusterR)
library(dbscan)
library(cluster)
library(tidyr)
# Read in the data
data <- read_delim("D:/February 2025/DSK804 Datamining og maskinlæring, forår 25. f/Project/marketing_campaign.csv", 
                   delim = "\t", escape_double = FALSE, 
                   trim_ws = TRUE)
# 1- DATA PREPROCESSING
# Drop irrelevant columns for clustering
cleaned_data <- data %>%
  select(-ID, -Dt_Customer, -Z_CostContact, -Z_Revenue)

# Check for missing values 
colSums(is.na(cleaned_data))
sum(is.na(cleaned_data))

# Remove rows with missing Income values
cleaned_data <- cleaned_data %>% filter(!is.na(Income))

# Create dummy variables for education & marital status 
cleaned_data <- dummy_cols(cleaned_data, select_columns = c("Education", "Marital_Status"), 
                           remove_first_dummy = TRUE, remove_selected_columns = FALSE)

# Check for constant columns
constant_cols <- sapply(cleaned_data, function(col) length(unique(col)) == 1)
print("Constant columns:")
print(constant_cols[constant_cols == TRUE])

# Define the marital status mapping
marital_status_map <- c(
  "Married" = 2,
  "Together" = 2,
  "Single" = 1,
  "Divorced" = 1,
  "Widow" = 1,
  "Alone" = 1,
  "Absurd" = 1,
  "YOLO" = 1
)

# Feature Engineering 
# Calculate Age
cleaned_data <- cleaned_data %>% mutate(Age = 2025 - Year_Birth)

# Calculate Family size
cleaned_data <- cleaned_data %>%
  mutate(
    Adults = marital_status_map[Marital_Status],  # lookup adults
    Family_Size = Adults + Kidhome + Teenhome     # sum them up
  )

# Calculate Total spending
cleaned_data <- cleaned_data %>% 
  mutate(TotalSpent = MntWines + MntFruits + MntMeatProducts + 
           MntFishProducts + MntSweetProducts + MntGoldProds)

# Select features for clustering
data_needed <- cleaned_data %>%
  select(Income, Age, TotalSpent, Family_Size)

# Scale the data for clustering (standardizes the values so that each feature has mean = 0 and standard deviation = 1.)
data_scaled <- scale(data_needed)
data_scaled <- as.data.frame(data_scaled)

# Run PCA
pca_result <- prcomp(data_scaled, scale. = FALSE)  # Already scaled the data

# Extract top PCs
pca_data <- as.data.frame(pca_result$x[, 1:2])  # Top 2 principal components

# Run KMeans on PCA results
set.seed(123)
kmeans_result <- kmeans(pca_data, centers = 3, nstart = 50)

# Plot the clusters (pass only numeric columns to fviz_cluster)
fviz_cluster(kmeans_result, data = pca_data[, 1:2], 
             ellipse.type = "norm",
             main = "KMeans after PCA")
pca_data$Cluster <- factor(kmeans_result$cluster)


########KMEANS CLUSTER SUMMARY#################
# Adding cluster label to original scaled data
clustered_data <- data_scaled
clustered_data$Cluster <- as.factor(kmeans_result$clusters)

# Getting average values of each variable by cluster
cluster_summary <- clustered_data %>%
  group_by(Cluster) %>%
  summarise(
    Avg_Income = mean(Income),
    Avg_Age = mean(Age),
    Avg_TotalSpent = mean(TotalSpent),
    Avg_FamilySize = mean(Family_Size)
  )
print(cluster_summary)

##BOX PLOT to see characteristics deviations##

data_with_clusters <- cleaned_data %>%
  select(Income, Age, TotalSpent, Family_Size) %>%
  mutate(Cluster = factor(kmeans_result$clusters))
##Income
ggplot(data_with_clusters, aes(x = Cluster, y = Income, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red", fill = "red") +
  labs(title = "Income Distribution by Cluster", y = "Income") +
  theme_minimal()
##Age
ggplot(data_with_clusters, aes(x = Cluster, y = Age, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  labs(title = "Age Distribution by Cluster", y = "Age") +
  theme_minimal()

##Total Spending
ggplot(data_with_clusters, aes(x = Cluster, y = TotalSpent, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  labs(title = "Total Spending by Cluster", y = "Total Spending") +
  theme_minimal()

##Family Size
ggplot(data_with_clusters, aes(x = Cluster, y = Family_Size, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  labs(title = "Family Size by Cluster", y = "Family Size") +
  theme_minimal()


######DBSCAN##########
dbscan_result <- dbscan(data_scaled, eps = 0.25, minPts = 16)
fviz_cluster(list(data = data_scaled, cluster = dbscan_result$cluster),
             geom = "point",
             stand = FALSE,
             main = "DBSCAN Clustering after PCA")
#DBSCAN with removed noise: 

#Run DBSCAN
dbscan_no_noise <- dbscan(data_scaled, eps = 0.25, minPts = 16)

# Combine data and cluster labels
# Note: we're using dbscan_no_noise instead of dbscan_result here
clustered_data <- data.frame(data_scaled, cluster = dbscan_no_noise$cluster)

# Remove noise (cluster == 0)
clean_data <- subset(clustered_data, cluster != 0)

# Plot clusters without noise
fviz_cluster(list(data = clean_data[, 1:(ncol(clean_data)-1)],  # All columns except 'cluster'
                  cluster = clean_data$cluster),
             geom = "point",
             stand = FALSE,
             main = "DBSCAN Clustering (Noise Removed)")

#####DBSCAN Cluster Summary#####

# Add DBSCAN cluster labels to scaled data
clustered_data <- data_scaled
clustered_data$Cluster <- dbscan_result$cluster  # Use your DBSCAN result object here

# Create summary table with mean of each variable by cluster
cluster_summary <- clean_data %>%
  group_by(cluster) %>%
  summarise(
    Avg_Income = mean(Income),
    Avg_Age = mean(Age),
    Avg_TotalSpent = mean(TotalSpent),
    Avg_FamilySize = mean(Family_Size)
  )
# Print the summary
print(cluster_summary)


#######BOX PLOT to see characteristics deviations######

# Filter out noise (cluster 0) and prepare data
data_with_clusters <- cleaned_data %>%
  select(Income, Age, TotalSpent, Family_Size) %>%
  mutate(Cluster = dbscan_result$cluster) %>%
  filter(Cluster != 0) %>%
  mutate(Cluster = factor(Cluster))

# Income Distribution
ggplot(data_with_clusters, aes(x = Cluster, y = Income, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red", fill = "red") +
  labs(title = "Income Distribution by DBSCAN Cluster (No Noise)", y = "Income") +
  theme_minimal()

# Age Distribution
ggplot(data_with_clusters, aes(x = Cluster, y = Age, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  labs(title = "Age Distribution by DBSCAN Cluster (No Noise)", y = "Age") +
  theme_minimal()

# Total Spending Distribution
ggplot(data_with_clusters, aes(x = Cluster, y = TotalSpent, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  labs(title = "Total Spending by DBSCAN Cluster (No Noise)", y = "Total Spending") +
  theme_minimal()

# Family Size Distribution
ggplot(data_with_clusters, aes(x = Cluster, y = Family_Size, fill = Cluster)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  labs(title = "Family Size by DBSCAN Cluster (No Noise)", y = "Family Size") +
  theme_minimal()


#############HIERARCHAL ALGORITHM ##########
dist_matrix <- dist(data_scaled)
hc <- hclust(dist_matrix, method = "ward.D2")
plot(hc)

# Cut the dendrogram into k clusters
groups <- cutree(hc, k = 3)

# Plot
plot(hc, labels = FALSE, hang = -1, cex = 0.6)  # no individual labels
rect.hclust(hc, k = 3, border = 2:4)

# Randomly Sample 100 observations
set.seed(123)
small_data <- data_scaled[sample(1:nrow(data_scaled), 100), ]

# Make HC cluster
small_dist <- dist(small_data)
small_hc <- hclust(small_dist, method = "ward.D2")

# Plot
plot(small_hc, labels = FALSE, hang = -1, cex = 0.7)
rect.hclust(small_hc, k = 3, border = 2:4)

######Silhouette Matrix######

# --- KMEANS ---
kmeans_sil <- silhouette(kmeans_result$clusters, dist(pca_data))
kmeans_avg_sil <- mean(kmeans_sil[, 3])

# --- DBSCAN ---
dbscan_sil <- silhouette(clean_data$cluster, dist(clean_data[, 1:(ncol(clean_data)-1)]))
dbscan_avg_sil <- mean(dbscan_sil[, 3])

# --- HIERARCHICAL CLUSTERING ---
hclust_labels <- cutree(hc, k = 3)
hclust_sil <- silhouette(hclust_labels, dist(pca_data))
hclust_avg_sil <- mean(hclust_sil[, 3])

# Combine into a data frame
silhouette_scores <- data.frame(
  Method = c("KMeans", "DBSCAN", "Hierarchical"),
  Silhouette_Coefficient = c(kmeans_avg_sil, dbscan_avg_sil, hclust_avg_sil)
)

print(silhouette_scores)

ggplot(silhouette_scores, aes(x = Method, y = Silhouette_Coefficient, fill = Method)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = round(Silhouette_Coefficient, 2)), vjust = -0.5, size = 4) +
  labs(title = "Average Silhouette Coefficient by Clustering Method",
       y = "Average Silhouette Coefficient", x = "Clustering Method") +
  theme_minimal()