

Insert Into DimAuthors
(AuthorID, AuthorName, AuthorCity, AuthorState)
Select 
 [AuthorID] = Cast(au_id as nvarchar(11))
,[AuthorName] = Cast(au_fname + ' ' + au_lname as varchar(100))
,[AuthorCity] = Cast(city as varchar(100))
,[AuthorState] =  Cast(state as char(2))
From IndependentBookSellers.dbo.Authors;
go

Insert Into DimTitles
(TitleID, TitleName, TitleType, TitleListPrice)
Select 
 [TitleID] = Cast(title_id as nvarchar(6))
,[TitleName] = Cast(title as varchar(100))
,[TitleType]=Case Cast(IsNull([type],'Unknown') as nvarchar(50) )
 When 'business' Then 'Business'
 When 'mod_cook' Then 'Modern Cooking'
 When 'popular_comp' Then 'Popular Computing'
 When 'psychology' Then 'Psychology'
 When 'trad_cook' Then 'Traditional Cooking'
 When 'UNDECIDED' Then 'Undecided'
 End
,[TitleListPrice] = price -- Should this be left as null?
From IndependentBookSellers.dbo.Titles;
go

Insert Into DimStores
(StoreID, StoreName, StoreCity, StoreState)
Select
 [StoreID] = Cast(stor_id as nchar(4))
,[StoreName] = Cast(stor_name as nvarchar(100))
,[StoreCity] = Cast(city as nvarchar(100))
,[StoreState] = Cast(state as nchar(2))
From IndependentBookSellers.dbo.Stores;
go

Insert Into FactTitleAuthors
(AuthorKey, TitleKey, AuthorOrder)
Select
 da.[AuthorKey]
,dt.[TitleKey]
,ta.[au_ord]
From IndependentBookSellers.dbo.TitleAuthors as ta
 Join DimAuthors as da 
  On ta.au_id = da.AuthorID
 Join DimTitles as dt
  On ta.title_id = dt.TitleID;
go

Insert Into FactSales
(OrderNumber, OrderDateKey, StoreKey, TitleKey, SalesQty, SalesPrice)
Select 
 [OrderNumber] = sh.ord_num
,[OrderDateKey] = Cast(Convert(nvarchar(50), sh.ord_date, 112) as int) 
,[StoreKey]
,[TitleKey]
,[SalesQty] = sd.qty
,[SalesPrice] = sd.price
From [IndependentBookSellers].[dbo].[SalesHeader] as sh
 Join [IndependentBookSellers].[dbo].[SalesDetails] as sd
  On sh.ord_num = sd.ord_num
 Join [DWIndependentBookSellers].[dbo].[DimStores] as ds
  On sh.stor_id = ds.StoreID
 Join [DWIndependentBookSellers].[dbo].[DimTitles] as dt
  On  sd.title_id = dt.TitleID