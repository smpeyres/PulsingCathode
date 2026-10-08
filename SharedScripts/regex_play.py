from filename_parse import filename_parse

name1 = "500Hz_25%_3mA.csv"
dict1 = filename_parse(name1)
print(dict1)

name2 = "9.5kHz_2.5%_8.7mA.csv"
print(filename_parse(name2))

print(filename_parse("9kHz_10%_8.5mA_2.csv"))

print(filename_parse("2khz_10%_3.5mA.csv"))

print(filename_parse("3mA_25per_500Hz_30March2026.jpg"))

print(filename_parse("7khz_2.5%_6.5ma0.csv"))
