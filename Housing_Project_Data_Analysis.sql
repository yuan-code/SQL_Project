/* Clean Data in SQL Queries */

SELECT *
FROM [Project].[dbo].[NashvilleHousing]



-- Standardize Data Format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM [Project].[dbo].[NashvilleHousing]

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM [Project].[dbo].[NashvilleHousing]



-- Indentify Missing Values
SELECT *
FROM [Project].[dbo].[NashvilleHousing]
WHERE SaleDateConverted IS NULL

SELECT *
FROM [Project].[dbo].[NashvilleHousing]
WHERE SalePrice IS NULL

-- Populate Property Address Data for NULL Values and Update the table
SELECT * 
FROM [Project].[dbo].[NashvilleHousing]
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Project].[dbo].[NashvilleHousing] a
JOIN [Project].[dbo].[NashvilleHousing] b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Project].[dbo].[NashvilleHousing] a
JOIN [Project].[dbo].[NashvilleHousing] b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



-- Breaking out Address into Individual Columns (Address, City, State) and Update the Table
SELECT PropertyAddress
FROM [Project].[dbo].[NashvilleHousing]

/* SUBSTRING(): extracts some characters from a string
   CHARINDEX(): searches for a substring in a string, and returns the position */
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM [Project].[dbo].[NashvilleHousing]

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM [Project].[dbo].[NashvilleHousing]


SELECT OwnerAddress
FROM [Project].[dbo].[NashvilleHousing]

/* PARSENAME(): parse and return individual segments in a "dot" delimited string (backwards) */
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS Address,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS City,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS State
FROM [Project].[dbo].[NashvilleHousing]

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

SELECT *
FROM [Project].[dbo].[NashvilleHousing]



-- Change 'Y' and 'N' to 'Yes' and 'No' in "Sold as Vacant" Field
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) AS CNT
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY SoldAsVacant
ORDER BY CNT

SELECT SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No' 
			 ELSE SoldAsVacant END
FROM [Project].[dbo].[NashvilleHousing]

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No' 
						ELSE SoldAsVacant END

SELECT DISTINCT SoldAsVacant
FROM [Project].[dbo].[NashvilleHousing]



-- Check and Remove Duplicates
WITH CTE AS
(
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS RN
FROM [Project].[dbo].[NashvilleHousing]
)

DELETE -- SELECT *
FROM CTE
WHERE RN > 1



-- Delete Unused Columns
SELECT *
FROM [Project].[dbo].[NashvilleHousing]

ALTER TABLE [Project].[dbo].[NashvilleHousing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


-----------------------------------------------------------------------------------------------------


-- Which year corresponds to highest number of sales
SELECT TOP 1 YEAR(SaleDateConverted) AS SaleYear, COUNT(*) AS SaleCount
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY YEAR(SaleDateConverted)
ORDER BY COUNT(*) DESC



-- What factors contribute to variations in property prices for houses
SELECT PropertySplitCity, Bedrooms, ROUND(AVG(SalePrice), 2) AS AvgPrice, MAX(SalePrice) AS MaxPrice, MIN(SalePrice) AS MinPrice, COUNT(*) AS SaleNum
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY PropertySplitCity, Bedrooms
ORDER BY AVG(SalePrice) DESC



-- Does the number of bedrooms have a noticeable impact on property prices
SELECT Bedrooms, ROUND(AVG(SalePrice), 2) AS AvgPrice, COUNT(*) AS SaleNum
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY Bedrooms
ORDER BY AvgPrice DESC



-- Does city location have a noticeable impact on property prices
SELECT PropertySplitCity, ROUND(AVG(SalePrice), 2) AS AvgPrice, COUNT(*) AS SaleNum
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY PropertySplitCity
ORDER BY AvgPrice DESC



-- Which city sells the highest number of houses
SELECT PropertySplitCity, COUNT(PropertySplitCity)
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY PropertySplitCity
ORDER BY COUNT(PropertySplitCity) DESC



-- How has the average property price changed over time?
SELECT YEAR(SaleDateConverted) AS SaleYear, ROUND(AVG(SalePrice), 2) AS AvgPrice
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY YEAR(SaleDateConverted)
ORDER BY AvgPrice DESC



-- Are there specific neighborhoods or postcodes that have shown consistent growth in property prices
WITH growth_cte AS
(
SELECT PropertySplitCity, YEAR(SaleDateConverted) AS SaleYear, ROUND(AVG(SalePrice), 2) AS AvgPrice
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY PropertySplitCity, YEAR(SaleDateConverted)
)
SELECT a.PropertySplitCity, a.SaleYear, (b.AvgPrice-a.AvgPrice)/a.AvgPrice * 100 AS PriceGrowthPercentage
FROM growth_cte a
JOIN growth_cte b
ON a.PropertySplitCity = b.PropertySplitCity AND a.SaleYear = b.SaleYear - 1
ORDER BY a.PropertySplitCity, a.SaleYear



-- Are there any patterns or trends in the dates of property sales
SELECT YEAR(SaleDateConverted) AS SaleYear, DATEPART(quarter, SaleDateConverted) AS SaleQuarter, COUNT(SalePrice) AS SaleNum
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY YEAR(SaleDateConverted), DATEPART(quarter, SaleDateConverted)
ORDER BY SaleYear, SaleNum DESC

SELECT YEAR(SaleDateConverted) AS SaleYear, MONTH(SaleDateConverted) AS SaleMonth, COUNT(SalePrice) AS SaleNum
FROM [Project].[dbo].[NashvilleHousing]
GROUP BY YEAR(SaleDateConverted), MONTH(SaleDateConverted)
ORDER BY SaleYear, SaleNum DESC