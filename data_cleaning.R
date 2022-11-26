library(tidyverse)
# read data
airline<- read_csv("https://storage.googleapis.com/kagglesdsdata/datasets/810/1496/airlines.csv?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=gcp-kaggle-com%40kaggle-161607.iam.gserviceaccount.com%2F20221124%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20221124T183834Z&X-Goog-Expires=259200&X-Goog-SignedHeaders=host&X-Goog-Signature=454e31c13ca21537e2336a1ed8e3060d95e2d4946117e9272e1ae6c2fe71d14886b3e75b536db0253818b1a7902e836f89e5d7ea8131e0ee1709ee16c34def92b4aa81011679b0bc5b10ee5cd140f936633b15a659e3241407fea461d64f22916a393a159bebeb49cb29ca190bc82e73476f0e39c4acc4c56a1217f4e4e71e575bdef9a36aaf31a281c71bc8569a4a68f60fd59ecc76badf8207c4c9bdcf6362c1d98aabafa6ffc7693501fa853bd7ac59746f3b2cb1822fc03a0ae938e5f8b4d3d0c7dcbae93ad998244e8c17cbd5117aa2f18eb74a24d69230e834d12b8c5aa23829e15344f3b5a0b1643e36e83a75829a5ffb7249dd42f39224d0e24cd693")
airports<- read_csv("https://storage.googleapis.com/kagglesdsdata/datasets/810/1496/airports.csv?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=gcp-kaggle-com%40kaggle-161607.iam.gserviceaccount.com%2F20221124%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20221124T183928Z&X-Goog-Expires=259200&X-Goog-SignedHeaders=host&X-Goog-Signature=49c0914a7d38b567e196750dfcabccef41d61137d2b471659e807ea4f0395830a3d76b04bdd66f2927c64be14cc5564e376248eebd72df6f305d292fcaddccf12512a921f4414fdff4abeced31e4b5aa1274ac49ba4bda510cdbc210a74ac20e9c11e4804e9f5c7ba7f77c68695f1ee0b7d4c1b45374e4183659980dbe92ec1c41c7ce32e74ff0a8a07699322bb6192ffd4ba3bf3ae69457d6c1ae55e4a22a1e4c5d0955216567085c996c62a43d40618a7ea4880b0d9e8aa4714c1b71f1773e98631b0dd1fe5a9091b97edd8e05ae3db6634fcaccefc39e14d0bc0ecf81a5c54b0c447f9c848b9628e47996f552515dc9821fec6fdde8e7eaba4295873f8c23")
flights<- read_csv("flights.csv") %>%
  filter(!(AIRLINE %in% c('EV','MQ','OO','US'))) 
# Remove MQ,EV,OO because regional
# Remove US due to merger
colnames(airports)<- tolower(colnames(airports))
colnames(flights)<- tolower(colnames(flights))

# join airport data to flights
flights<- left_join(flights, airports, by=c('destination_airport' = 'iata_code'))

# create 95%-tile data frame to define delay
percentile_95<- flights %>%
  group_by(airline) %>%
  summarise(percentile_95 = quantile(arrival_delay, 0.95, na.rm = T))

# create 95%-tile data frame to define delay by state
percentile_95_state<- flights %>%
  group_by(state) %>%
  summarise(percentile_95 = quantile(arrival_delay, 0.95, na.rm = T))

# create 95%-tile data frame to define delay by od
percentile_95_od<- flights %>%
  mutate(od = ifelse(origin_airport>destination_airport, 
                     paste0(destination_airport, origin_airport), 
                     paste0(origin_airport, destination_airport))) %>%
  group_by(od) %>%
  summarise(percentile_95 = quantile(arrival_delay, 0.95, na.rm=T)) %>%
  filter(!str_starts(od,'\\d'))

# create 95%-tile data frame to define delay by arrival airport
percentile_95_vol<- flights %>%
  group_by(destination_airport) %>%
  summarise(percentile_95 = quantile(arrival_delay, 0.95, na.rm=T)) %>%
  filter(!str_starts(destination_airport,'\\d'))


# delay across airlines in the year
monthly_delay<- flights %>%
  left_join(percentile_95, "airline") %>%
  mutate(delay_bool = ifelse((arrival_delay>15)&(arrival_delay<percentile_95),1,0)) %>%
  group_by(month, airline) %>%
  summarise(average_delay = mean(delay_bool, na.rm = T))

# delay across airline types in the year
monthly_delay_type<- flights %>%
  left_join(percentile_95, "airline") %>%
  mutate(type = case_when(airline %in% c('AA','DL','UA') ~ 'Legacy',
                          airline %in% c('B6, AS','VX') ~ 'LCC',
                          airline %in% c('NK', 'F9') ~ 'ULCC',
                          airline == 'WN' ~ 'WN',
                          airline == 'HA' ~ 'HA'),
         delay_bool = ifelse((arrival_delay>15)&(arrival_delay<percentile_95),1,0)) %>%
  group_by(month, type) %>%
  summarise(average_delay = mean(delay_bool, na.rm = T)) %>%
  filter(!(is.na(type)))

# delay by state
delay_state<- flights %>%
  left_join(percentile_95_state, "state") %>%
  mutate(delay_bool = ifelse((arrival_delay>15)&(arrival_delay<percentile_95),1,0)) %>%
  group_by(state) %>%
  summarise(average_delay = mean(delay_bool, na.rm = T))

# by od
delay_od<- flights %>%
  mutate(od = ifelse(origin_airport>destination_airport, 
                     paste0(destination_airport, origin_airport), 
                     paste0(origin_airport, destination_airport))) %>%
  right_join(percentile_95_od, 'od') %>%
  mutate(delay_bool = ifelse((arrival_delay>15)&(arrival_delay<percentile_95),1,0)) %>%
  group_by(od, airline) %>%
  summarise(average_delay = mean(delay_bool, na.rm = T)) %>%
  group_by(od) %>%
  summarise(num_airlines = n(), average_delay = mean(average_delay)) %>%
  filter(num_airlines >= 3) %>%
  arrange(desc(average_delay)) %>%
  mutate(origin = substr(od,1,3),
         dest = substr(od,4,6)) %>%
  left_join(airports, by = c("origin" = "iata_code")) %>%
  left_join(airports, by = c("dest" = "iata_code"), suffix = c("_origin", "_destination"))
write.csv(delay_od, "data/delay_od.csv")


# by volume
delay_volume<- flights %>%
  right_join(percentile_95_vol, 'destination_airport') %>%
  mutate(delay_bool = ifelse((arrival_delay>15)&(arrival_delay<percentile_95),1,0)) %>%
  group_by(destination_airport) %>%
  summarise(num_flights = n(), average_delay = mean(delay_bool, na.rm = T))

cor(delay_volume$num_flights, delay_volume$average_delay)


a<- delay_volume %>%
  filter((num_flights >= 10000)&(num_flights<=80000))
cor(a$num_flights, a$average_delay)
