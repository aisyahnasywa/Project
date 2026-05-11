# This script performs spatial thinning on raw GPS collar datasets. 
# Due to the high-frequency sampling of the GPS collars, the raw data contains 
# a massive number of points that are prone to spatial redundancy and 
# autocorrelation. Spatial thinning is applied to ensure data independence 
# and improve the reliability of subsequent spatial modeling.


#load package
library(spThin)
library(dplyr)

#readcsv
data_asli <- read.csv("TelemetriGajah.csv", sep = ";")
head(data_asli)
colnames(data_asli)
str(data_asli)

#choose 1000 random data from each elephant group, if it contain less than 1000 data then choose all
data_pra_seleksi <- data_asli %>%
  group_by(Gajah) %>%
  sample_n(size = min(n(), 1000)) %>%
  ungroup() 

# check the selected data and compare with the pre-selection
print("Jumlah titik per kelompok SETELAH pra-seleksi:")
print(table(data_pra_seleksi$Gajah))
total_setelah_seleksi <- nrow(data_pra_seleksi)
print(paste("Total titik setelah pra-seleksi:", total_setelah_seleksi))

#separate data for each elephant group
head(data_pra_seleksi)
colnames(data_pra_seleksi)
str(data_pra_seleksi)
data_untuk_thinning <- data.frame(
  species   = data_pra_seleksi$Gajah,    # <-- PERUBAHAN UTAMA DI SINI
  longitude = data_pra_seleksi$Lon,
  latitude  = data_pra_seleksi$Lat
)

# check the separated data
head(data_untuk_thinning)
total_data_untuk_thinning <- nrow(data_untuk_thinning)
print(paste("Total titik:", total_data_untuk_thinning))

#choose the thinning distance (minimum 2x resolution)
jarak_thinning_km <- 0.05 # in km unit

# repetition number
jumlah_repetisi <- 100

# save as
nama_output <- "gajah_thinned_50mFIX"

#spatialthinning process
thin(
  loc.data = data_untuk_thinning,
  lat.col = "latitude",         # Nama kolom latitude di data frame baru kita
  long.col = "longitude",       # Nama kolom longitude di data frame baru kita
  spec.col = "species",         # Nama kolom spesies di data frame baru kita
  thin.par = jarak_thinning_km,
  reps = jumlah_repetisi,
  locs.thinned.list.return = TRUE,
  write.files = TRUE,
  out.dir = ".",
  out.base = nama_output
)

print("Proses penjarangan selesai!")
print(paste("Hasil disimpan di folder kerja Anda:", getwd()))

# Check the result
nama_file_hasil <- paste0(nama_output, "_thin1.csv")
data_hasil_thinning <- read.csv(nama_file_hasil)

print(paste("Jumlah titik awal:", nrow(data_asli)))
print(paste("Jumlah titik setelah dijarangkan:", nrow(data_hasil_thinning)))

#split into training and testing data
# read thinned csv
tryCatch({
  data_final <- read.csv(nama_file_hasil)
}, error = function(e) {
  stop(paste("Eror: File", nama_file_hasil, "tidak ditemukan. Pastikan Anda sudah menjalankan skrip spThin sebelumnya dan berada di folder kerja yang benar."))
})
head(data_final)

#seed set
set.seed(123) # pick randomly

# get the total row
total_data <- nrow(data_final)

# 70% split for training data
jumlah_training <- floor(0.70 * total_data)

# sort data and pick randomly for training data
indeks_semua_data <- 1:total_data
indeks_training <- sample(indeks_semua_data, size = jumlah_training)

# set the rest as testing data
indeks_testing <- setdiff(indeks_semua_data, indeks_training)

# Buat dua data frame baru berdasarkan indeks yang sudah dibagi
data_training_70 <- data_final[indeks_training, ]
data_testing_30 <- data_final[indeks_testing, ]

# show the final result
print(paste("Total data awal:", total_data))
print(paste("Jumlah data training (70%):", nrow(data_training_70)))
print(paste("Jumlah data testing (30%):", nrow(data_testing_30)))
cat("\n")

# save the final result
write.csv(data_training_70, file = "gajah_training_70.csv", row.names = FALSE)
write.csv(data_testing_30, file = "gajah_testing_30.csv", row.names = FALSE)