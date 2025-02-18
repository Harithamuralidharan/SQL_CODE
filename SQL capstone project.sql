/*     Project Steps and Objectives    */

use ecomm;
-- /***  Data Cleaning ***/ --
-----   Handling Missing Values and Outliers  -----
select * from customer_churn;

-- Disable safe updates
Set SQL_SAFE_UPDATES= 0;

-- calculate rounded mean value using user_defind variables
Set @WarehouseToHome = (Select round(avg(WarehouseToHome)) from customer_churn) ;
Set @HourSpendOnApp= (Select round(avg(HourSpendOnApp))  from customer_churn) ;
Set @OrderAmountHikeFromlastYear = (Select round(avg(OrderAmountHikeFromlastYear)) from customer_churn );
		Set @DaySinceLastOrder = (Select round(avg(DaySinceLastOrder)) from customer_churn );
		 
		-- impute mean
update customer_churn
Set WarehouseToHome = @WarehouseToHome
where WarehouseToHome is null;

update customer_churn
Set HourSpendOnApp = @HourSpendOnApp
where HourSpendOnApp is null;

update customer_churn
Set OrderAmountHikeFromlastYear = @OrderAmountHikeFromlastYear
where OrderAmountHikeFromlastYear is null;

update customer_churn
Set DaySinceLastOrder = @DaySinceLastOrder
where DaySinceLastOrder is null;

-- -- calculate rounded mode value using user_defind variables
set @Tenure = (Select Tenure from customer_churn group by Tenure order by count(*)  desc limit 1 );
set @CouponUsed = (Select   CouponUsed from customer_churn group by CouponUsed order by count(*)  desc limit 1) ;
set @OrderCount = (Select  OrderCount from customer_churn group by OrderCount order by count(*) desc limit 1 );

-- impute mode
update customer_churn
Set Tenure = @Tenure
where Tenure is null;

update customer_churn
Set CouponUsed = @CouponUsed
where CouponUsed is null;

update customer_churn
Set OrderCount = @OrderCount
where OrderCount is null;

-- Handling outliners in 'WarehouseToHome' column
Delete from customer_churn
where WarehouseToHome  > 100 ;

-- /*** Dealing with Inconsistencies ***/--
-- Replace occurrences of “Phone” in the 'PreferredLoginDevice' column

update  customer_churn
Set PreferredLoginDevice = IF (PreferredLoginDevice = 'Phone','Mobile Phone',PreferredLoginDevice);

update customer_churn
Set PreferedOrderCat= IF (PreferedOrderCat= 'Mobile','Mobile Phone',PreferedOrderCat);

-- Standardize payment mode values:
 update customer_churn
 Set PreferredPaymentMode = case
                     when PreferredPaymentMode = 'COD' then 'Cash on Delivery'
                     when PreferredPaymentMode = 'CC' then 'Credit Card'
                     else PreferredPaymentMode 
					END;
                     
      -- /*** Data Transformation ***/ --
-------- Column Renaming ----------

Alter table customer_churn
Rename column PreferedOrderCat to PreferredOrderCat,
Rename column HourSpendOnApp to HoursSpentOnApp ;

-------- Creating New Columns -------
	
Alter table customer_churn
Add column ComplaintReceived Enum ("yes","no"),
Add column ChurnStatus Enum ("churned","Active");

-- set the value from the new column based on existing column

Update customer_churn
set ComplaintReceived = If(Complain = 1, "Yes","No"),
    ChurnStatus = If(Churn =  1, "churned","Active");
    
----------- Column Dropping -----------

Alter table customer_churn
Drop column Complain,
Drop column Churn ;

-- /*** Data Exploration and Analysis ***/ --
-- 1.
Select ChurnStatus , count(*) count_churn from customer_churn group by ChurnStatus ;

-- 2.
Select Round(avg(tenure)) average_value from customer_churn Where ChurnStatus = "churned";

-- 3. 
Select sum(CashbackAmount) total_amount from customer_churn Where ChurnStatus = "churned";

-- 4. 
Select ChurnStatus , concat(round(count(*)/(Select count(*) from customer_churn ) * 100, 2), '%') As Churn_complain
From customer_churn
Where ComplaintReceived = "yes"
group by ChurnStatus;

-- 5.
Select Gender, count(*) from customer_churn
Where ComplaintReceived = "yes"
group by Gender;

-- 6. 
Select CityTier, count(*) city_status
from customer_churn
where  ChurnStatus = "churned" and PreferredOrderCat = "Laptop & Accessory"
group by CityTier ;

-- 7.
Select PreferredPaymentMode, count(*) payment_count from customer_churn
where ChurnStatus = "Active"
group by PreferredPaymentMode 
order by payment_count desc limit 1 ;

-- 8.
Select PreferredLoginDevice, count(*) customer_devices from customer_churn
where DaySinceLastOrder > 10
group by PreferredLoginDevice ;

-- 9
select count(ChurnStatus)  Active_customer_in_app from customer_churn
where ChurnStatus = "Active" and HoursSpentOnApp > 3;

-- 10
Select Round(avg(CashbackAmount)) customer_cashback from customer_churn
where HoursSpentOnApp > 1
group by CashbackAmount;

-- 11 
select PreferredOrderCat ,max( HoursSpentOnApp ) max_hours from customer_churn 
group by PreferredOrderCat
order by max_hours desc;

-- 12
Select  MaritalStatus ,concat("$ ",round(avg(OrderAmountHikeFromlastYear),2)) avg_orderamt
From customer_churn
group by MaritalStatus
order by MaritalStatus desc;

-- 13 
select MaritalStatus, PreferredOrderCat,sum(OrderAmountHikeFromlastYear) total_order_amt  from customer_churn
where MaritalStatus = "single"  and  PreferredOrderCat = "Mobile Phone";

-- 14 
select PreferredPaymentMode, round(avg(NumberOfDeviceRegistered)) num_reg_devices From customer_churn
where PreferredPaymentMode = "UPI";

-- 15 
select CityTier ,count(CustomerID) customer_count from customer_churn
group by CityTier
order by customer_count desc;

-- 16 
select MaritalStatus, max(NumberOfAddress) highest_numofadddress from customer_churn
group by MaritalStatus;

-- 17
select Gender, max(CouponUsed)  highest_couponused from customer_churn
group by Gender;

-- 18 
select PreferredOrderCat , round(avg(SatisfactionScore),2) avg_sats_score from customer_churn
group by PreferredOrderCat;

-- 19
select PreferredPaymentMode, max(SatisfactionScore) highest_score, count(OrderCount) order_count from customer_churn
where PreferredPaymentMode = "Debit Card"
group by PreferredPaymentMode;

-- 20 
select HoursSpentOnApp,  count(CustomerID) num_of_customer from customer_churn
where HoursSpentOnApp =1 and DaySinceLastOrder > 5;

-- 21
select ComplaintReceived , round(avg(SatisfactionScore),2) avg_score from customer_churn
where ComplaintReceived ="yes";

-- 22 
select PreferredOrderCat , count(CustomerID) num_cus from customer_churn
group by PreferredOrderCat
order by num_cus desc;

-- 23 
select MaritalStatus, concat("$",round(avg(CashbackAmount),2)) avg_cashback_cus from customer_churn
where MaritalStatus = "Married";

-- 24 
select PreferredLoginDevice, round(avg(NumberOfDeviceRegistered)) register_devices from customer_churn
where PreferredLoginDevice not in ("Mobile Phone")
group by PreferredLoginDevice

-- 25 
select PreferredOrderCat from customer_churn
where CouponUsed > 5
group by PreferredOrderCat;

-- 26 
select PreferredOrderCat ,concat( "$",round(avg(CashbackAmount),2)) highest_avg_cashback from customer_churn
group by PreferredOrderCat
order by highest_avg_cashback desc limit 3;

-- 27 
select PreferredPaymentMode ,count(*) as countof_order from customer_churn
where tenure = 10 and OrderCount > 500
group by PreferredPaymentMode 
order by PreferredPaymentMode desc;

-- 28
select
 case 
   when WarehouseToHome <= 5 then 'Very Close Distance'
   when WarehouseToHome <= 10 then 'Close Distance'
   when WarehouseToHome <=15 then 'Moderate Distance'
   else 'Far Distance'
end as distance_category,
ChurnStatus , count(*) from customer_churn
group by distance_category ,ChurnStatus;
select * from customer_churn;
-- 29 
set @orderCountOfCustomer = (select avg(OrderCount) from customer_churn );

select MaritalStatus ,count(OrderCount) from customer_churn
where MaritalStatus = "married" and CityTier = 1 and OrderCount > @orderCountOfCustomer;

-- 30
-- (a)
DROP TABLE IF EXISTS customer_returns;
CREATE table customer_returns(
ReturnID int ,
CustomerID int,
ReturnDate int,
RefundAmount int,
foreign key (CustomerID) references customer_churn(CustomerID)  
); 

Insert into customer_returns( ReturnID ,CustomerID,ReturnDate,RefundAmount)
value(1001,50022,2023-01-01,2130),
(1002,50316,2023-01-23,20000),
(1003,51099,2023-02-14,2290),
(1004,52321,2023-03-08,2510),
(1005,52928,2023-03-20,3000),
(1006,53749,2023-04-17,1740),
(1007,54206,2023-04-21,3250),
(1008,54838,2023-04-30,1990);

-- (b)
select c.CustomerID,
Tenure,
PreferredLoginDevice,
CityTier,
WarehouseToHome, 
PreferredPaymentMode, 
Gender, 
HoursSpentOnApp,
NumberOfDeviceRegistered, 
PreferredOrderCat, 
SatisfactionScore, 
MaritalStatus,
NumberOfAddress, 
OrderAmountHikeFromlastYear, 
CouponUsed,
OrderCount, 
DaySinceLastOrder,
CashbackAmount,
ComplaintReceived, 
ChurnStatus
from customer_churn c
inner join customer_returns cr on c.CustomerID = cr.CustomerID
where ChurnStatus ='churned' and ComplaintReceived ='yes' ;