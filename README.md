Project aim is sell original gps tracking device. 
Project was build using Postgres, AWS, activeadmin, googlemapsapi and hosted on heroku

1 task to export information about ordes to csv

Almost all code is in lib/csv.
Thedatabase has next structure User with email, name, address has many BravoOrders
BravoOrderr with specific color, quantity can have or not have profile 
Profile can include up to 10 unique engraving strings
User ould also have few different addresses 

For each user I had to put one line with email.
For each unique address I had to create new line.
For his orders with profile a had to put new line for unique engraving, and related quantities 
For orders without profiles I had to sum quantities for unique colors

Exmaple
Serial ID   Name   Address    Engraving   Accessory pack   Quantity   Colors
                                                                     Black  Gray Sky blue Rose gold
1..2  1..2  Alex   Test addr  First                            2        1     1             
 3     5    James  Test addr2                                                       1   
 4     7                      Second                           1                             1

 2 Referral program 

 I have created referral program system.
 Admin can create referral program at admin panel,with different for different types of products(Wallet trackr, Stickr trackr  or Bravo trackr) with different prizes (free product of some type or discount) and number of users customer needs to invite
 Admin can create program with demand to share information about TrackR on facebook or twetter
 When user buy new product he can select referral program from a list.
 He will see wether link to refer friends or link to share on facebook or tweeter.
 When he accomplish referral program user will get free device added to his current unsheeped order or credit in case of discount.
 If user have credit he can use it while next purchase.

 All system works with cookies a lot, because site does not have usual account system, user can not sigh in.
 Some parameters like domain and expiration time should be added to cookies.

 3 Coordinates

 I created model for importing  coordinates(longitude,latitude) to the database I used Postgres and active record do to small  amout of data but Redis would be a good alternative.
 Created task crowdgps_import.rake to import data from csv file
 Then data was loaded to javascript with ajax call and displayed on the main page using googlemaps api. 
