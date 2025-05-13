# Intro / Setup -----------------------------------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(janitor)

# Set your own script to work in the right local directory:
setwd('C:\\Users\\dwrig\\Documents\\GitHub\\is-555-07-end-to-end-dwright343')


long <- read_csv('https://www.dropbox.com/s/9luewx3rekalme9/mh_long.csv?dl=1')
wide <- read_csv('https://www.dropbox.com/s/il32xg5lrgza06m/mh_wide.csv?dl=1')


# Your Code: --------------------------------------------------------------------------------------------

### 1. wide_clean
wide_renamed <- wide %>% select(id, propertyName, streetAddress, addressLocality, addressRegion, postalCode, latitude, longitude) %>% clean_names()

columns <- colnames(wide_renamed)
missing_locality_ids <- c('18ca29da-6390-4d38-bd9f-a56c1ce42f37', '21c8755a-19f0-4424-81b5-461bc756a6e9')
missing_locations <- wide_renamed %>% filter_at(vars(all_of(columns)), any_vars(is.na(.))) %>% arrange(id) %>% 
  filter(!id %in% missing_locality_ids)
missing_locations

# This subset of duplicates doesn't having missing values.
duplicates <- wide_renamed %>% filter(duplicated(id)) %>% arrange(id)
duplicates

drop_na <- wide_renamed %>% drop_na()
drop_na

missing_data <- bind_rows(duplicates, drop_na) %>% arrange(id)

missing_data %>% filter(duplicated(id)) %>% arrange(id)

florida_missing <- wide_renamed %>% filter(id == '18ca29da-6390-4d38-bd9f-a56c1ce42f37')
florida_replace <- florida_missing %>% mutate(address_locality = 'Lee', 
                                              postal_code  = '32059',
                                              address_region  = 'FL')

washington_missing <- wide_renamed %>% filter(id == '21c8755a-19f0-4424-81b5-461bc756a6e9')
washington_replace <- washington_missing %>% mutate(address_locality = 'Forest Beach', 
                                                    postal_code = '98528',
                                                 address_region  = 'WA')

special_cases <- bind_rows(florida_replace, washington_replace) 
# %>% filter(id == '18ca29da-6390-4d38-bd9f-a56c1ce42f37')

wide_clean <- unique(bind_rows(special_cases, missing_data))

# check for na again
wide_clean %>% filter_at(vars(all_of(columns)), any_vars(is.na(.))) %>% arrange(id)
wide_clean %>% filter(longitude < -83)

# check for dupes again
wide_clean %>% filter(duplicated(id)) %>% arrange(id)




### 2. long_clean_pivoted
long %>% dplyr::summarise(n = dplyr::n(), .by = c(id, key)) |>
  dplyr::filter(n > 1L)

# code the has_ features
coded <- long %>% mutate(value = case_when(
  key == 'Laundromat' ~ "1",
  key == 'Storage' ~ "1",
  key == 'Club House' ~ "1",
  key == 'Pool' ~ "1",
  key == 'Handicap Accessible' ~ "1",
  .default = value)
)
# long %>% filter(id == '3b3548e0-ac8d-43a2-92a2-f28194a017cb')

# pivot_wider & clean names
pivoted <- coded %>% 
  group_by(id, key) %>% 
  mutate(row = row_number())  %>% 
  pivot_wider(names_from = key,
              values_from = value) %>% 
  unique() %>% clean_names() %>% ungroup()

# rename _has features
renamed <- pivoted %>% rename(has_laundromat = laundromat, has_storage = storage, has_club_house = club_house, has_pool = pool, has_handicap_accessible = handicap_accessible)

# code _has features with 0
coded_zero <- renamed %>%
  mutate_at(vars(has_laundromat, has_storage, has_club_house, has_pool, has_handicap_accessible), ~ replace_na(., "0")) 

# check for duplicates
coded_zero %>% filter(duplicated(id)) %>% select(id, price, posted_on, updated_on)

duplicate_list <- coded_zero %>% filter(duplicated(id) | duplicated(id, fromLast = TRUE)) %>% select(id, price, posted_on, updated_on)

left_chunk <- coded_zero %>% filter(!duplicated(id))

# take the lower price
lower_price <- duplicate_list %>% group_by(id) %>% slice_min(price) %>% select(id, price)
# and the dates
dates <- duplicate_list %>% group_by(id) %>% filter(!is.na(posted_on) | !is.na(updated_on)) %>% select(id, posted_on, updated_on)

# take the most recent price
price_chunk <- inner_join(lower_price, dates)

# reconstruct price data
recent_price <- left_join(left_chunk, price_chunk)

# double check for duplicates
recent_price %>% filter(duplicated(id))


#convert prices to numeric and rename cols
price_transform <- recent_price %>% 
  # price -> +_usd
  mutate(price = gsub("[$,]", '', price)) %>% 
  mutate(price = as.double(price)) %>% rename(price_usd = price) %>% 
  
  # average_mh_lot_rent -> +_usd
  mutate(average_mh_lot_rent = gsub("[$,]", '', average_mh_lot_rent)) %>% 
  mutate(average_mh_lot_rent = as.double(average_mh_lot_rent)) %>% rename(average_mh_lot_rent_usd = average_mh_lot_rent) %>% 

  # average_rent_for_park_owned_homes -> +_usd
  mutate(average_rent_for_park_owned_homes = gsub("[$,]", '', average_rent_for_park_owned_homes)) %>% 
  mutate(average_rent_for_park_owned_homes = as.double(average_rent_for_park_owned_homes)) %>% 
  rename(average_rent_for_park_owned_homes_usd = average_rent_for_park_owned_homes) %>% 
  
  # average_rv_lot_rent
  mutate(average_rv_lot_rent = gsub("[$,]", '', average_rv_lot_rent)) %>% 
  mutate(average_rv_lot_rent = as.double(average_rv_lot_rent)) %>% 
  rename(average_rv_lot_rent_usd = average_rv_lot_rent)


# convert dates to date types
date_transform <- price_transform %>% 
  mutate(posted_on = mdy(posted_on)) %>% 
  mutate(updated_on = mdy(updated_on)) %>% 
  # clean year_built
  mutate(year_built = if_else(year_built < 1500, NA, year_built))

# handle extra data in year_built
cut_year <- date_transform %>% mutate(year_built = if_else(str_length(year_built) > 4, str_sub(year_built, start = 5), year_built) )

# convert numbers to numeric types
numeric_cols <- c('number_of_mh_lots', 'has_laundromat', 
                  'has_storage', 'has_club_house', 'has_pool', 
                  'has_handicap_accessible', 'singlewide_lots', 
                  'number_of_park_owned_homes', 'doublewide_lots', 'number_of_rv_lots', 'year_built')
converted_nm <- cut_year %>% mutate_at(numeric_cols, as.numeric)

# clean total_occupancy
trimmed_cols <- converted_nm %>% mutate(total_occupancy = gsub("[\\n\n%]", '', total_occupancy)) %>% 
  mutate(total_occupancy = .01 * as.double(total_occupancy)) %>% 
  rename(total_occupancy_rate = total_occupancy) %>% 
# clean size
  mutate(size = str_trim(gsub("[\n acre(s)]", ' ', size))) %>% 
  mutate(size = as.double(size)) %>% rename(size_acres = size) %>% 
# clean int_rate
  mutate(interest_rate = gsub("%", "", interest_rate)) %>% 
  mutate(interest_rate = .01 * as.double(interest_rate))

# check values
# trimmed_cols %>% group_by(purchase_method) %>% summarize(count = n())

# dummy code the purchase methods
purchase_m_coded <- trimmed_cols %>% mutate(purchase_method = gsub(" ", "_", purchase_method)) %>% 
  mutate(method_list = strsplit(purchase_method,",_")) %>% unnest(method_list) %>% 
  pivot_wider(names_from = method_list, values_from = method_list, values_fn = length) %>% 
  select(-c(`NA`, row))

long_clean_pivoted <- purchase_m_coded %>% rename(cash = Cash, new_loan = New_Loan, 
                              seller_financing = Seller_Financing,
                              assumable_loan = Assumable_Loan)


### 3. together_clean
together <- inner_join(long_clean_pivoted, wide_clean, by = "id")

# add calculated cols
together_calc <- together %>% mutate(age_years = year(today()) - year_built) %>% 
  mutate(price_per_lot_usd = price_usd / number_of_mh_lots) %>% 
  # clean up price
  mutate(price_usd = if_else(price_usd < 1000, NA, price_usd))

together_clean <- together_calc

### 4. plot_1
plot_1 <- together_clean %>% ggplot(aes(x = price_usd,)) +
  geom_density(alpha = 0.6, fill='blue') +
  labs(
    title = "Density Distribution of Price (USD)",
    x = "Price in USD",
    y = "Density",
  ) +
  theme_bw()
  

### 5. plot_2
plot_2 <- together_clean %>% ggplot(aes(x = log(price_usd))) +
  geom_density(alpha = 0.6, fill='blue') +
  labs(
    title = "Density Distribution of Price (USD), Log Scale",
    x = "Price in USD, Log Scale",
    y = "Density",
  ) + xlim(8,20)
  theme_bw()

### 6. plot_3
plot_3 <- together_clean %>% filter(posted_on > '2022-01-01') %>% 
  ggplot(aes(x = posted_on)) +
  geom_histogram(alpha = 0.6, fill='red') +
  labs(
    title = "Properties over time",
    x = "Date Posted (30 Bins)",
    y = "Count of Properties",
  ) + 
theme_bw()

### 7. plot_4
plot_4 <- together_clean %>% 
  ggplot(aes(x = age_years)) + 
  geom_histogram(alpha = 0.6, fill='green') + 
  labs(
    title = "Property Age in Years",
    x = "Age (30 Bins)",
    y = "Count of Properties",
  ) + 
  theme_bw()

### 8. plot_5
plot_5 <- together_clean %>% mutate(has_purchase_method = if_else(is.na(purchase_method), "No", "Yes")) %>% 
  ggplot(aes(x = address_region, fill = purchase_method)) +
  geom_bar() +
  facet_wrap(~has_purchase_method, ncol = 1, labeller = label_both) +  
  labs(
    title = "Count of Properties by State",
    x = "State",
    y = "Count of Properties"
  ) + 
  theme(
    axis.text.x = element_text(angle = 90, hjust =1)
  )
  theme_bw()

# Pre-Submission Checks --------------------------------------------------------------------------------

# The checks run by the command below will see whether you have named your objects 
# and columns exactly correct. Any issues it finds will be reported in the console. 
# If it see what it expects to see, you'll instead see a message that "All naming 
# tests passed."

source('submission_checks.R')
