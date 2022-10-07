select * from saleslt.customer

-- 1.1

select 
SalesPerson
, concat(Title, LastName) as CustomerName
, Phone
from saleslt.customer

select * from saleslt.product 
-- 1.2
SELECT 
top(10) PERCENT Name
, Weight
,DATEDIFF(day, SellStartDate, ISNULL(SellEndDate, CURRENT_TIMESTAMP)) as NumberOfSellDays 
FROM saleslt.product
ORDER BY Weight DESC

-- 2.1
select 
CONCAT(CustomerID,': ', CompanyName)
from saleslt.customer

-- 2.2
select * from SalesLT.SalesOrderHeader 

SELECT 
CONCAT(SalesOrderNumber, ' (',RevisionNumber,')') AS SalesOrderAndRevisionNumber
, CONVERT ( varchar(20), OrderDate, 102) AS NewOrderTime
FROM SalesLT.SalesOrderHeader 

-- 3.1
select 
concat(FirstName, ' ', MiddleName, ' ', LastName) AS CustomerContactName
from saleslt.customer

select 
IIF(MiddleName IS NULL, FirstName + ' ' + LastName, FirstName + ' ' + MiddleName + ' ' + LastName) AS CustomerContactName 
from saleslt.customer

-- 3.2

select 
CustomerID
, IIF(EmailAddress is null, Phone, EmailAddress) as PrimaryContact
from saleslt.customer


-- 3.3
SELECT 
CustomerID
, CompanyName
, CONCAT(FirstName, ' ', LastName) AS ContactName
, Phone
FROM SalesLT.Customer
WHERE CustomerID NOT IN (SELECT CustomerID FROM Saleslt.CustomerAddress)








select *
from saleslt.customer

select *
from saleslt.customeraddress 
where addressID in (select AddressID from saleslt.Address )

select * 
from saleslt.Address

