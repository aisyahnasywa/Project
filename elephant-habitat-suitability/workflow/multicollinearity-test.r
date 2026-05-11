
# Multicollinearity Analysis (GVIF)

#load packages
library(terra) # Untuk membaca dan memproses data raster (.asc)
library(car)   # Untuk menghitung GVIF

#setwd
setwd("D:/Kuliah")

# List all .asc files in folder
file_list <- list.files(pattern = "\\.asc$")
print(file_list)

# raster processing
raster_stack <- rast(file_list)
names(raster_stack) <- c("elevasi", "jarak_hutan", "jarak_permukiman", "jarak_sungai", "ndvi", "PL", "slope")
print(raster_stack)

# random sample
sampled_points <- spatSample(raster_stack, 2000, "random", na.rm = TRUE)
sampled_points$PL <- as.factor(sampled_points$PL) #PL=categorized variable
str(sampled_points)

#model making
model_dummy <- lm(elevasi ~ ., data = sampled_points)

#calculate gvif, this function automatically calculate vif for continuous variable and gvif for categorized
gvif_results <- vif(model_dummy)
print("Hasil Analisis GVIF:")
print(gvif_results)

#save csv
write.csv(gvif_results, file = "hasil_gvif.csv")