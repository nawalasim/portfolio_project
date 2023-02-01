--Data Cleaning Project
SELECT *
FROM portfolio_project.dbo.Nash_housing$
--WHERE PropertyAddress is Null
----------------------------------------------------------------------------------------

--1. Standardize Date format

ALTER TABLE portfolio_project.dbo.Nash_housing
ADD SaleDateConverted Date;

Update portfolio_project.dbo.Nash_housing$
SET SaleDateConverted= CONVERT(Date,SaleDate);

SELECT SaleDateConverted
FROM portfolio_project.dbo.Nash_housing$




-------------------------------------------------------------------------------------------------------------
--2. Filling in the Nulls in Property address using parcel ID

--(First running a query to check and confirm without updating the table)

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) as update_col
FROM portfolio_project.dbo.Nash_housing$ a 
JOIN portfolio_project.dbo.Nash_housing$ b
ON a.ParcelID=b.ParcelID and
 a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress is null

 --Now updating the original Table using the above query

Update a
SET a.PropertyAddress=ISNULL(a.propertyAddress, b.PropertyAddress)
FROM portfolio_project.dbo.Nash_housing$ a 
JOIN portfolio_project.dbo.Nash_housing$ b
ON a.ParcelID=b.ParcelID and
 a.[UniqueID ] <> b.[UniqueID ]

 --double check running the first query again and we get no nulls for Property Table




 ------------------------------------------------------------------------------------------------------------------------------------
 --3. Seperating the address into address, city etc

 --using CharIndex to seperate on the delimiter ','
 SELECT PropertyAddress,
 SUBSTRING(PropertyAddress, 1, CHARINDEX( ',', PropertyAddress) -1) as address,
 SUBSTRING(PropertyAddress, CHARINDEX( ',', PropertyAddress) +1, LEN(PropertyAddress) )as city
 FROM portfolio_project.dbo.Nash_housing$

 --makign a column in the table and adding the above query 
 ALTER TABLE portfolio_project.dbo.Nash_housing$
 ADD Property_split_address Nvarchar(255);

 UPDATE portfolio_project..Nash_housing$
 SET Property_split_address= SUBSTRING(PropertyAddress, 1, CHARINDEX( ',', PropertyAddress) -1);

 ALTER TABLE portfolio_project.dbo.Nash_housing$
 ADD Property_split_city Nvarchar(255);

 UPDATE portfolio_project..Nash_housing$
 SET Property_split_city=  SUBSTRING(PropertyAddress, CHARINDEX( ',', PropertyAddress) +1, LEN(PropertyAddress) );






------------------------------------------------------------------------------------------------------------------------
--4. Splitting Owner address into address, state and city using PARSENAME

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as city,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as state
FROM portfolio_project.dbo.Nash_housing$

--makign a column in the table and adding the above query 
 ALTER TABLE portfolio_project.dbo.Nash_housing$
 ADD Owner_split_address Nvarchar(255);

 UPDATE portfolio_project..Nash_housing$
 SET Owner_split_address= PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

 ALTER TABLE portfolio_project.dbo.Nash_housing$
 ADD Owner_split_city Nvarchar(255);

 UPDATE portfolio_project..Nash_housing$
 SET Owner_split_city=  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

 ALTER TABLE portfolio_project.dbo.Nash_housing$
 ADD Owner_split_state Nvarchar(255);

 UPDATE portfolio_project..Nash_housing$
 SET Owner_split_state=  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);






 ---------------------------------------------------------------------------------------------------------
 --5. Setting SaleAsVacant column to binary eihter yes or no in same format:

 SELECT SoldAsVacant
 ,CASE WHEN SoldAsVacant='Y' THEN 'Yes'
	  WHEN SoldAsVacant='N' THEN 'No'
	  ELSE SoldAsVacant
	  END
 FROM portfolio_project.dbo.Nash_housing$

 UPDATE portfolio_project.dbo.Nash_housing$
 SET SoldAsVacant=CASE WHEN SoldAsVacant='Y' THEN 'Yes'
	  WHEN SoldAsVacant='N' THEN 'No'
	  ELSE SoldAsVacant
	  END

--to check above query:
 SELECT SoldAsVacant, Count(SoldAsVacant)
  FROM portfolio_project.dbo.Nash_housing$
  GROUP BY SoldAsVacant





  ------------------------------------------------------------------------------------------------------------------------------------
  --6. First identifying duplincates using rownum function and then deleting them from our data:
WITH rownumCTE as(
SELECT *, ROW_NUMBER() OVER(PARTITION BY ParcelID, 
							LandUse, 
							PropertyAddress,
							SalePrice,
							SaleDate,
							LegalReference
							ORDER BY uniqueID) row_num
							FROM portfolio_project.dbo.Nash_housing$)
DELETE 
FROM rownumCTE
WHERE row_num>1
 
 --Now to delete

 




 ------------------------------------------------------------------------------------------------------
 --7. DELETING UNUSED ROWS
 ALTER TABLE portfolio_project.dbo.Nash_housing$
 DROP COLUMN SaleDate, PropertyAddress, OwnerAddress

