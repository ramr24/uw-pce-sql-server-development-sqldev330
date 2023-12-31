Use Pubs;
Go
Select Count(*) from pubs.dbo.Titles; -- 18 with nulls
Select Count(*) from pubs.dbo.Titles where Price > 0; --16 due to nulls
Select Count(*) from pubs.dbo.Titles where Price > 10; --12
Go

Declare @MinPrice money = 10;
Select Count(*) from pubs.dbo.Titles where Price > @MinPrice;
Go 

Declare @MinPrice money = 10, @TitleCount int;
Select @TitleCount = Count(*) from pubs.dbo.Titles where Price > @MinPrice;
Select @TitleCount as [Number of Titles about min price];
Go

Create -- Drop
Procedure pSelTitleCountByMinPrice
(@MinPrice money, @TitleCount int output)
AS
Begin
 Declare @RC int; -- Used to indicate status of code execution
 Begin Try
  Select @TitleCount = Count(*) from pubs.dbo.Titles where Price > @MinPrice;
  Set @RC = 100;
 End Try
 Begin Catch
  Set @RC = -100;
 End Catch
 Return @RC;
End
Go

Declare @ReturnCode int, @CountOutput int;
Exec @ReturnCode = pSelTitleCountByMinPrice
 @MinPrice = 10
,@TitleCount = @CountOutput output;

Select 
 @CountOutput as [Number of Titles about min price]
,@ReturnCode as [Status of Code];
Go