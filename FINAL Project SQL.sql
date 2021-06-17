--Group Members: Eleanor Pulsipher, Sarah Hellmann

--The Script
USE IT_Startup

--To get user defined objects from database:
SELECT * FROM sys.objects WHERE [Type] = 'U';

--See dept and employee tables:
SELECT * FROM Employee;		
SELECT * FROM Department;

--FR1: Human Resources
--Add new Ops into dept table:
INSERT INTO Department
VALUES (3, 'Operations');
--Add new dept (dept 4) for executives:
INSERT INTO Department
VALUES (4, 'Executives');
--Add column  Head to employee table
ALTER TABLE Employee
ADD Head TINYINT;
--Add executives' data to employee table:
INSERT INTO Employee (Employee_ID, FirstName, LastName, Gender, Position, Dept_ID)
VALUES (3011, 'Sarah', 'Hellmann', 'F', 'Executive', 4),
	   (3012, 'Eleanor', 'Pulsipher', 'F', 'Executive', 4),
	   (3013, 'Chrissy', 'Teigon', 'F', 'Executive', 4); 
--Add 1 to head col where executives are heads:
UPDATE Employee
SET Head = 1
WHERE Position = 'Executive'
--Add 0 to head col where executives are not heads:
UPDATE Employee
SET Head = 0
WHERE Position <> 'Executive'
SELECT * FROM employee

--FR2: Data Model: Client, View, Pricing, TypeClient, and AgentRegion Tables

--CLIENT TABLE:
--Create Client table:
CREATE TABLE Client(
ClientID INT,
[Name] NVARCHAR(40),
TypeID SMALLINT,
City NVARCHAR(25),
Region NVARCHAR(6),
Pricing SMALLINT
);
--Populate the client table with bulk insert:
BULK INSERT Client 
FROM 'C:\Users\Sarah Hellmann\Desktop\MGSC 7100 (SQL Data Fund and BI)\Mod 10\Client.csv'
WITH 
(	 FIRSTROW = 2		
	, FIELDTERMINATOR = ','
	, ROWTERMINATOR = '\n'
);
GO

--VIEW TABLE:
--Create View table:
CREATE TABLE [View](
ViewID INT,
ViewDate DATETIME,
ID INT,
Device NVARCHAR(25),
Browser NVARCHAR(30),
Host VARCHAR(15)
);
--Populate the View table with bulk insert:
BULK INSERT [dbo].[View]
FROM 'C:\Users\Sarah Hellmann\Desktop\MGSC 7100 (SQL Data Fund and BI)\Mod 10\View.txt'
WITH 
(	 FIRSTROW = 2		
	, FIELDTERMINATOR = '\t'
	, ROWTERMINATOR = '\n'
);
GO

--PRICING TABLE:
--Create Pricing table:
CREATE TABLE Pricing(
	PlanNo SMALLINT PRIMARY KEY
	, PlanName VARCHAR(8) NOT NULL
	, Monthly FLOAT
);
--Populate Pricng table:
BULK INSERT Pricing
FROM 'C:\Users\Sarah Hellmann\Desktop\MGSC 7100 (SQL Data Fund and BI)\Case Study\Pricing.txt'
WITH (FIRSTROW = 2		
	, FIELDTERMINATOR = '\t'
	, ROWTERMINATOR = '\n'
);
GO

--CLIENTTYPE TABLE:
--Create ClientType table:
CREATE TABLE ClientType(
	TypeName NVARCHAR(100)
	, TypeID SMALLINT
);
--Populate ClientType table:
BULK INSERT ClientType
FROM 'C:\Users\Sarah Hellmann\Desktop\MGSC 7100 (SQL Data Fund and BI)\Case Study\ClientType.txt'
WITH (FIRSTROW = 2		
	, FIELDTERMINATOR = '\t'
	, ROWTERMINATOR = '\n'
);
GO

--AGENTREGION TABLE:
--Create AgentRegion table:
CREATE TABLE AgentRegion( 
	Region NVARCHAR(6)
	, EmployeeID BIGINT
);
--Populate AgentRegion table:
BULK INSERT AgentRegion
FROM 'C:\Users\Sarah Hellmann\Desktop\MGSC 7100 (SQL Data Fund and BI)\Case Study\AgentRegion.txt'
WITH (FIRSTROW = 2		
	, FIELDTERMINATOR = '\t'
	, ROWTERMINATOR = '\n'
);
GO

--See New tables:
SELECT * FROM Client
SELECT * FROM [View]
SELECT * FROM Pricing
SELECT * FROM ClientType
SELECT * FROM AgentRegion

--Entity Relationship Model - attached with submission on Canvas

--FR3: Queries

--Q1:Top ten Spas & Salons that have the highest views
SELECT TOP 10 c.[Name]
	, c.ClientID
	, ct.TypeName
	, Count(v.viewID) as [View Count]
FROM Client c JOIN ClientType ct ON c.TypeID = ct.TypeID
			  JOIN [View] v ON c.ClientID = v.ID
WHERE TypeName = 'Spas & Salons'
GROUP BY c.[Name], c.ClientID, ct.TypeName
ORDER BY [View Count] DESC;
GO

--Q2: All clients whose names start OR end with the term Grill, along with their cities, subscription fees, and number of views.
SELECT c.Name
	, c.City
	, p.Monthly AS [Monthly Fees]
	,Count(v.viewID) AS [View Count]
FROM Client c JOIN [View] v ON c.ClientID = v.ID
			  JOIN Pricing p ON c.Pricing = p.PlanNo
WHERE c.Name LIKE 'Grill%' OR c.Name LIKE '%Grill'
GROUP BY c.Name, c.City, p.Monthly; 
GO

--Q3: Count of client types (Restaurant, etc.) with their average views per client and average subscription fees sorted with respect to average views per client in descending order.

	--Sarah's Method:
SELECT ct.TypeName
	,COUNT(c.TypeID) AS [Count of Client Types]
	, AVG(vc.Count)
	, AVG(p.Monthly) as [Monthly Avg Fees]
FROM Client c JOIN ClientType ct ON c.TypeID = ct.TypeID
			  JOIN Pricing p ON c.Pricing = p.PlanNo,
			  (SELECT COUNT(v.ViewID) AS 'Count'
			   FROM [View] v
			   GROUP BY v.ID) AS vc
GROUP BY ct.TypeID, ct.TypeName
ORDER BY AVG(p.Monthly);
GO
	--Eleanor's Method:
SELECT 
	ct.TypeName
	, COUNT(DISTINCT(c.ClientID)) AS [Count of Clients in Type] 
	, AVG(p.Monthly) as [Monthly Avg Fees]
	, FORMAT(Count(v.ViewID)/COUNT(DISTINCT c.ClientID), 'G') AS [Avg Views per Client]
FROM Client c JOIN ClientType ct ON c.TypeID = ct.TypeID
			  JOIN Pricing p ON c.Pricing = p.PlanNo
			  JOIN [View] v ON c.ClientID = v.ID
GROUP BY ct.TypeID, ct.TypeName
ORDER BY [Avg Views per client] DESC;
GO

-- FR3.Q4: Cities for which total number of views for non-restaurant (not typeid=13) clients are more than 20.
SELECT c.City
	, COUNT(v.ViewID) as [Non-Restaurant View Count]
FROM Client c JOIN [View] v ON c.ClientID = v.ID
			  JOIN ClientType ct ON c.TypeID = ct.TypeID
WHERE NOT c.TypeID = 13
GROUP BY c.City
HAVING COUNT(v.ViewID) > 20;
GO

--FR3.Q5: Number of clients, average fees, average views with respect to the hosts in a descending order of average views.
	--Sarah's Method:
SELECT 
	COUNT(DISTINCT c.ClientID) as [Number of Clients]
	, AVG(p.Monthly) as [Avg Monthly Fees]
	, AVG(vc.Count) AS [Avg Views]
FROM Client c JOIN Pricing p ON c.Pricing = p.PlanNo
			  JOIN [View] v ON c.ClientID = v.ID
			  ,(SELECT COUNT(v.ViewID) AS 'Count'
			   FROM [View] v
			   GROUP BY v.ID) AS vc
GROUP BY v.Host
ORDER BY len(AVG(vc.Count)) DESC, [Avg Views] DESC;
GO 

	--Eleanor's Method:
SELECT 
	v.Host,
	COUNT(DISTINCT c.ClientID) as [Number of Clients], 
	AVG(p.Monthly) as [Avg Fees], 
	FORMAT(Count(v.ViewID)/COUNT(DISTINCT c.ClientID), 'n') AS [Avg Views]
FROM Client c 
			JOIN [View] V ON c.ClientID = v.ID
			JOIN Pricing p ON c.Pricing = p.PlanNo			
GROUP BY v.Host
ORDER BY len(FORMAT(Count(v.ViewID)/COUNT(DISTINCT c.ClientID), 'n')) DESC, [Avg Views] DESC;
GO

--FR3.Q6: number of clients, their total fees, total views, and average fees per views w.r.to regions, sorted in descending order of average fees per views.
SELECT 
	c.Region
	, COUNT(Distinct c.[Name]) AS [Number of Clients] 
	, COUNT(v.ViewID) AS [Number of Views]
	, SUM(p.Monthly) AS [Total Fees]
	, FORMAT(SUM(p.Monthly)/COUNT(v.ViewID), 'N') AS [Avg Fees per Views]
FROM Client c 
			JOIN [View] v ON c.ClientID = v.ID 
			JOIN Pricing p ON c.Pricing = p.PlanNo
GROUP BY c.Region
ORDER BY len(FORMAT(SUM(p.Monthly)/COUNT(v.ViewID), 'N')) DESC, [Avg Fees per Views] DESC;
GO 

--FR3.Q7: All views (all columns) that took place after October 15th, by Kindle devices, hosted by Yelp from cities where there are more than 200 client
SELECT v.*
	, c.[Name]
	, c.City
	, ci.[Client Count per City]
FROM [View] v 
			JOIN Client c ON v.ID = c.ClientID
			,(SELECT COUNT(c.ClientID) as 'Client Count per City'
			 FROM Client c
			 GROUP BY c.City
			 HAVING COUNT(c.ClientID) > 200) as ci
WHERE v.ViewDate >= '2019-10-16 00:00:00' AND v.Host = 'yelp' AND v.Device = 'kindle';
GO

-- FR3.Q8: All non-executive employee full names in the first column, number of their regions, number of their clients, and number of views for those clients in columns 2, 3, and 4, respectively.
SELECT 
	CONCAT(e.FirstName, ' ', e.LastName) AS [Employee Name] 
	, COUNT(DISTINCT ar.Region) as [Number of Regions]
	, COUNT(DISTINCT c.ClientID) as [Number of Clients] 
	, COUNT(DISTINCT v.ViewID) as [Number of Views]
FROM Employee e
				JOIN AgentRegion ar ON e.Employee_ID = ar.EmployeeID
				JOIN Client c ON ar.Region = c.Region
				JOIN [View] v ON c.ClientID = v.ID
GROUP BY CONCAT(e.FirstName, ' ', e.LastName);
GO

--FR 4- Business Intelligence
--FRBI-1: Price and View Count by Client
SELECT c.ClientID
	, c.[Name]
	, COUNT(v.ViewID) AS [Num of Views]
	, p.Monthly AS [Price Paid]
FROM Client c
			JOIN [View] v ON c.ClientID = v.ID 
			JOIN Pricing p ON c.Pricing = p.PlanNo
GROUP BY c.ClientID, c.[Name], p.Monthly;
GO

--FRBI-2: Number of views and hour (1-24)
SELECT FORMAT(COUNT(v.ViewID)/COUNT(DISTINCT v.ViewID)
	, DATENAME(HOUR, DATEADD(HOUR, 1, v.ViewDate))) AS [Avg Num of Views]
	, DATENAME(HOUR, DATEADD(HOUR, 1, v.ViewDate)) AS [Hour]
FROM [View] v 
GROUP BY DATENAME(HOUR, DATEADD(HOUR, 1, v.ViewDate));
GO
--Export to excel for BI Analysis: save results to CSV
	-- Excel analysis attached with submission on Canvas
