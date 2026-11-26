USE master;
GO

CREATE DATABASE BidNile;
GO

USE BidNile;
GO

CREATE SCHEMA Operations AUTHORIZATION dbo;
GO
CREATE SCHEMA Accounts AUTHORIZATION dbo;
GO
CREATE SCHEMA Catalog AUTHORIZATION dbo;
GO
CREATE SCHEMA Sales AUTHORIZATION dbo;
GO

CREATE TABLE Operations.City
(
    Id INT  PRIMARY KEY IDENTITY(1, 1)  NOT NULL,
    [Name] NVARCHAR(60) NOT NULL,
    CountryCode CHAR(2) NOT NULL,


    CONSTRAINT UQ_City_CountryCode_Name UNIQUE (CountryCode, [Name])
);

CREATE TABLE Accounts.Member
(
    Id UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Member_MemberId DEFAULT (NEWID()),
    CityId INT NOT NULL,
    InvitedByMemberId UNIQUEIDENTIFIER NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(254) NOT NULL,
    Mobile VARCHAR(16) NOT NULL
        CONSTRAINT CK_Member_Mobile CHECK (DATALENGTH(Mobile) BETWEEN 2 AND 16),
    NationalIdOrPassport VARCHAR(20) NOT NULL,
    BirthDate DATE NOT NULL,
    IsVerified BIT NOT NULL
        CONSTRAINT DF_Member_IsVerified DEFAULT (0),
    RegisteredAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Member_RegisteredAt DEFAULT (SYSUTCDATETIME()),



    CONSTRAINT PK_Member PRIMARY KEY (Id),
    CONSTRAINT UQ_Member_Email UNIQUE (Email),
    CONSTRAINT UQ_Member_NationalIdOrPassport UNIQUE (NationalIdOrPassport),
    CONSTRAINT CK_Member_BirthDate CHECK (BirthDate <= DATEADD(YEAR, -18, CONVERT(DATE, RegisteredAt))),
    CONSTRAINT CK_Member_InvitedByMemberId CHECK (InvitedByMemberId IS NULL OR InvitedByMemberId <> Id)
);

CREATE TABLE Accounts.Wallet
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    Balance DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Wallet_Balance DEFAULT (0.00)
        CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0),
    HeldAmount DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Wallet_HeldAmount DEFAULT (0.00),
    Currency CHAR(3) NOT NULL
        CONSTRAINT DF_Wallet_Currency DEFAULT ('EGP')
        CONSTRAINT CK_Wallet_Currency CHECK (Currency COLLATE Latin1_General_100_BIN2 LIKE '[A-Z][A-Z][A-Z]'),
    UpdatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Wallet_UpdatedAt DEFAULT (SYSUTCDATETIME()),



    CONSTRAINT PK_Wallet PRIMARY KEY (MemberId),
    CONSTRAINT CK_Wallet_HeldAmount CHECK (HeldAmount >= 0 AND HeldAmount <= Balance)
);

CREATE TABLE Operations.Warehouse
(
    Id INT IDENTITY(1, 1) NOT NULL,
    [Name] NVARCHAR(80) NOT NULL,
    Capacity INT NOT NULL
        CONSTRAINT CK_Warehouse_Capacity CHECK (Capacity > 0),
    CityId INT NOT NULL,
    Latitude FLOAT(53) NOT NULL
        CONSTRAINT CK_Warehouse_Latitude CHECK (Latitude BETWEEN -90 AND 90),
    Longitude FLOAT(53) NOT NULL
        CONSTRAINT CK_Warehouse_Longitude CHECK (Longitude BETWEEN -180 AND 180),
    ManagerId UNIQUEIDENTIFIER NULL,
    ManagerStartDate DATE NULL,



    CONSTRAINT PK_Warehouse PRIMARY KEY (Id),
    CONSTRAINT UQ_Warehouse_Name UNIQUE ([Name]),
    CONSTRAINT UQ_Warehouse_ManagerId UNIQUE (ManagerId),
    CONSTRAINT CK_Warehouse_ManagerStartDate CHECK
    (
        (ManagerId IS NULL AND ManagerStartDate IS NULL)
        OR (ManagerId IS NOT NULL AND ManagerStartDate IS NOT NULL)
    )
);

CREATE TABLE Operations.Employee
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    WarehouseId INT NOT NULL,
    CONSTRAINT PK_Employee PRIMARY KEY (MemberId)
);

CREATE TABLE Catalog.Category
(
    CategoryCode INT NOT NULL,
    ParentCategoryCode INT NULL,
    NameEn VARCHAR(50) NOT NULL,
    NameAr NVARCHAR(50) NULL,
    CommissionPercent DECIMAL(4, 2) NOT NULL
        CONSTRAINT CK_Category_CommissionPercent CHECK (CommissionPercent BETWEEN 0.00 AND 30.00),



    CONSTRAINT PK_Category PRIMARY KEY (CategoryCode),
    CONSTRAINT UQ_Category_NameEn UNIQUE (NameEn),
    CONSTRAINT CK_Category_ParentCategoryCode CHECK (ParentCategoryCode IS NULL OR ParentCategoryCode <> CategoryCode)
);

CREATE TABLE Catalog.Item
(
    ItemId INT IDENTITY(1, 1) NOT NULL,
    CategoryCode INT NOT NULL,
    WarehouseId INT NULL,
    SellerId UNIQUEIDENTIFIER NOT NULL,
    InspectorId UNIQUEIDENTIFIER NULL,
    Title NVARCHAR(150) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    ConditionScore TINYINT NOT NULL
        CONSTRAINT CK_Item_ConditionScore CHECK (ConditionScore BETWEEN 1 AND 10),
    Specifications NVARCHAR(MAX) NOT NULL
        CONSTRAINT CK_Item_Specifications CHECK (ISJSON(Specifications) = 1),
    ListedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Item_ListedAt DEFAULT (SYSUTCDATETIME()),


    CONSTRAINT PK_Item PRIMARY KEY (ItemId),
    CONSTRAINT CK_Item_InspectorId CHECK (InspectorId IS NULL OR InspectorId <> SellerId)
);

CREATE TABLE Catalog.Photo
(
    ItemId INT NOT NULL,
    [Position] TINYINT NOT NULL
        CONSTRAINT CK_Photo_Position CHECK ([Position] BETWEEN 1 AND 20),
    Url VARCHAR(500) NOT NULL,
    IsMain BIT NOT NULL
        CONSTRAINT DF_Photo_IsMain DEFAULT (0),


    CONSTRAINT PK_Photo PRIMARY KEY (ItemId, [Position])
);

CREATE TABLE Sales.Auction
(
    AuctionId INT IDENTITY(1, 1) NOT NULL,
    ItemId INT NOT NULL,
    StartingPrice DECIMAL(12, 2) NOT NULL
        CONSTRAINT CK_Auction_StartingPrice CHECK (StartingPrice > 0),
    ReservePrice DECIMAL(12, 2) NULL,
    BidIncrement DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Auction_BidIncrement DEFAULT (50.00)
        CONSTRAINT CK_Auction_BidIncrement CHECK (BidIncrement > 0),
    StartsAt DATETIMEOFFSET(3) NOT NULL,
    EndsAt DATETIMEOFFSET(3) NOT NULL,
    [Status] VARCHAR(13) NOT NULL
        CONSTRAINT DF_Auction_Status DEFAULT ('Draft')
        CONSTRAINT CK_Auction_Status CHECK ([Status] COLLATE Latin1_General_100_BIN2 IN ('Draft', 'Live', 'Ended', 'Cancelled')),


    CONSTRAINT PK_Auction PRIMARY KEY (AuctionId),
    CONSTRAINT CK_Auction_ReservePrice CHECK (ReservePrice IS NULL OR ReservePrice >= StartingPrice),
    CONSTRAINT CK_Auction_EndsAt CHECK (EndsAt > StartsAt)
);

CREATE TABLE Sales.Bid
(
    BidId BIGINT IDENTITY(1, 1) NOT NULL,
    AuctionId INT NOT NULL,
    MemberId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(12, 2) NOT NULL
        CONSTRAINT CK_Bid_Amount CHECK (Amount > 0),
    PlacedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Bid_PlacedAt DEFAULT (SYSUTCDATETIME()),
    IpAddress VARCHAR(45) NOT NULL,


    CONSTRAINT PK_Bid PRIMARY KEY (BidId),
    CONSTRAINT UQ_Bid_AuctionId_Amount UNIQUE (AuctionId, Amount)
);

CREATE TABLE Sales.AuctionFollow
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    AuctionId INT NOT NULL,
    FollowedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_AuctionFollow_FollowedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_AuctionFollow PRIMARY KEY (MemberId, AuctionId)
);
GO

-- Task 3
BEGIN TRY
    BEGIN TRANSACTION;

    -- 3.1
    ALTER TABLE Accounts.Member WITH CHECK ADD CONSTRAINT FK_Member_City
        FOREIGN KEY (CityId) REFERENCES Operations.City (Id);

    -- 3.1
    ALTER TABLE Accounts.Member WITH CHECK ADD CONSTRAINT FK_Member_Member
        FOREIGN KEY (InvitedByMemberId) REFERENCES Accounts.Member (Id);

    -- 3.1
    ALTER TABLE Accounts.Wallet WITH CHECK ADD CONSTRAINT FK_Wallet_Member
        FOREIGN KEY (MemberId) REFERENCES Accounts.Member (Id);

    -- 3.1
    ALTER TABLE Operations.Warehouse WITH CHECK ADD CONSTRAINT FK_Warehouse_City
        FOREIGN KEY (CityId) REFERENCES Operations.City (Id);

    -- 3.1
    ALTER TABLE Operations.Employee WITH CHECK ADD CONSTRAINT FK_Employee_Member
        FOREIGN KEY (MemberId) REFERENCES Accounts.Member (Id);

    -- 3.1
    ALTER TABLE Operations.Employee WITH CHECK ADD CONSTRAINT FK_Employee_Warehouse
        FOREIGN KEY (WarehouseId) REFERENCES Operations.Warehouse (Id);

    -- 3.1
    ALTER TABLE Operations.Warehouse WITH CHECK ADD CONSTRAINT FK_Warehouse_Employee
        FOREIGN KEY (ManagerId) REFERENCES Operations.Employee (MemberId);

    -- 3.1
    ALTER TABLE Catalog.Category WITH CHECK ADD CONSTRAINT FK_Category_Category
        FOREIGN KEY (ParentCategoryCode) REFERENCES Catalog.Category (CategoryCode);

    -- 3.1
    ALTER TABLE Catalog.Item WITH CHECK ADD CONSTRAINT FK_Item_Category
        FOREIGN KEY (CategoryCode) REFERENCES Catalog.Category (CategoryCode);

    -- 3.1
    ALTER TABLE Catalog.Item WITH CHECK ADD CONSTRAINT FK_Item_Warehouse
        FOREIGN KEY (WarehouseId) REFERENCES Operations.Warehouse (Id);

    -- 3.1
    ALTER TABLE Catalog.Item WITH CHECK ADD CONSTRAINT FK_Item_Member
        FOREIGN KEY (SellerId) REFERENCES Accounts.Member (Id);

    -- 3.1
    ALTER TABLE Catalog.Item WITH CHECK ADD CONSTRAINT FK_Item_Employee
        FOREIGN KEY (InspectorId) REFERENCES Operations.Employee (MemberId);

    -- 3.1
    ALTER TABLE Catalog.Photo WITH CHECK ADD CONSTRAINT FK_Photo_Item
        FOREIGN KEY (ItemId) REFERENCES Catalog.Item (ItemId) ON DELETE CASCADE;

    -- 3.1
    ALTER TABLE Sales.Auction WITH CHECK ADD CONSTRAINT FK_Auction_Item
        FOREIGN KEY (ItemId) REFERENCES Catalog.Item (ItemId);

    -- 3.1
    ALTER TABLE Sales.Bid WITH CHECK ADD CONSTRAINT FK_Bid_Auction
        FOREIGN KEY (AuctionId) REFERENCES Sales.Auction (AuctionId);

    -- 3.1
    ALTER TABLE Sales.Bid WITH CHECK ADD CONSTRAINT FK_Bid_Member
        FOREIGN KEY (MemberId) REFERENCES Accounts.Member (Id);

    -- 3.1
    ALTER TABLE Sales.AuctionFollow WITH CHECK ADD CONSTRAINT FK_AuctionFollow_Member
        FOREIGN KEY (MemberId) REFERENCES Accounts.Member (Id);

    -- 3.1
    ALTER TABLE Sales.AuctionFollow WITH CHECK ADD CONSTRAINT FK_AuctionFollow_Auction
        FOREIGN KEY (AuctionId) REFERENCES Sales.Auction (AuctionId);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- 3.2
ALTER TABLE Accounts.Member ADD AppLanguage CHAR(2) NOT NULL
    CONSTRAINT DF_Member_AppLanguage DEFAULT ('ar')
    CONSTRAINT CK_Member_AppLanguage CHECK (AppLanguage COLLATE Latin1_General_100_BIN2 IN ('ar', 'en'));
GO

-- 3.3
ALTER TABLE Catalog.Item ADD IsFeatured BIT NOT NULL
    CONSTRAINT DF_Item_IsFeatured DEFAULT (0);
GO

-- 3.4
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC sys.sp_rename N'Sales.Bid.IpAddress', N'DeviceIp', N'COLUMN';

    -- 3.4
    ALTER TABLE Operations.Warehouse DROP CONSTRAINT CK_Warehouse_Capacity;
    EXEC sys.sp_rename N'Operations.Warehouse.Capacity', N'MaxItems', N'COLUMN';

    -- 3.4
    EXEC sys.sp_executesql N'
        -- 3.4
        ALTER TABLE Operations.Warehouse WITH CHECK ADD CONSTRAINT CK_Warehouse_Capacity
            CHECK (MaxItems > 0);';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- 3.5
ALTER TABLE Accounts.Member ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM Operations.Warehouse WHERE MaxItems > 30000)
        THROW 50006, 'Resolve warehouse capacities above 30000 before applying change 3.6.', 1;

    -- 3.6
    ALTER TABLE Operations.Warehouse DROP CONSTRAINT CK_Warehouse_Capacity;

    -- 3.6
    ALTER TABLE Operations.Warehouse ALTER COLUMN MaxItems SMALLINT NOT NULL;

    -- 3.6
    ALTER TABLE Operations.Warehouse WITH CHECK ADD CONSTRAINT CK_Warehouse_MaxItems
        CHECK (MaxItems BETWEEN 1 AND 30000);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM Catalog.Category WHERE CommissionPercent > 25.00)
        THROW 50007, 'Resolve commissions above 25 percent before applying change 3.7', 1;

    -- 3.7
    ALTER TABLE Catalog.Category DROP CONSTRAINT CK_Category_CommissionPercent;

    -- 3.7
    ALTER TABLE Catalog.Category WITH CHECK ADD CONSTRAINT CK_Category_CommissionPercent
        CHECK (CommissionPercent BETWEEN 0.00 AND 25.00);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- 3.8
    ALTER TABLE Sales.Auction DROP CONSTRAINT CK_Auction_Status, DF_Auction_Status;

    -- 3.8
    ALTER TABLE Sales.Auction WITH CHECK ADD CONSTRAINT CK_Auction_Status
        CHECK ([Status] COLLATE Latin1_General_100_BIN2 IN ('Draft', 'Live', 'Ended', 'Cancelled', 'PendingReview'));

    -- 3.8
    ALTER TABLE Sales.Auction ADD CONSTRAINT DF_Auction_Status DEFAULT ('PendingReview') FOR [Status];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- 3.9
ALTER TABLE Sales.Auction WITH CHECK ADD
    BuyNowPrice DECIMAL(12, 2) NULL,
    CONSTRAINT CK_Auction_BuyNowPrice CHECK (BuyNowPrice IS NULL OR BuyNowPrice > StartingPrice);
GO

-- 3.10
IF EXISTS (SELECT Mobile FROM Accounts.Member GROUP BY Mobile HAVING COUNT_BIG(*) > 1)
    THROW 50010, 'Resolve duplicate member mobiles before applying change 3.10', 1;

-- 3.10
ALTER TABLE Accounts.Member ADD CONSTRAINT UQ_Member_Mobile UNIQUE (Mobile);
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- 3.11
    ALTER TABLE Accounts.Member ADD VerifiedAt DATETIME2(3) NULL;

    -- 3.11
    ALTER TABLE Accounts.Member DROP CONSTRAINT DF_Member_IsVerified;

    -- 3.11
    ALTER TABLE Accounts.Member DROP COLUMN IsVerified;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- 3.12
CREATE SCHEMA Marketing AUTHORIZATION dbo;
GO

-- 3.12
ALTER SCHEMA Marketing TRANSFER Sales.AuctionFollow;
GO
