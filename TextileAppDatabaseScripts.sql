CREATE TABLE `ClientDetails` (
  `ClientId` bigint(20) NOT NULL AUTO_INCREMENT,
  `FullName` varchar(50) NOT NULL,
  `Address` varchar(1024) NOT NULL,
  `GSTIN` varchar(32) NOT NULL,
  `State` varchar(32) NOT NULL,
  `PinCode` bigint(20) NOT NULL,
  PRIMARY KEY (`ClientId`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE `GatePass` (
  `PassNo` bigint(20) NOT NULL AUTO_INCREMENT,
  `FullName` varchar(50) NOT NULL,
  `ChallanNo` bigint(20) NOT NULL,
  `Quality` varchar(32) NOT NULL,
  `LotNo` varchar(32) NOT NULL,
  `Date` date NOT NULL,
  `ToPerson` varchar(50) NOT NULL,
  PRIMARY KEY (`PassNo`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `LoginUser` (
  `UserName` varchar(32) NOT NULL,
  `Password` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `SlipDetails` (
  `PassNo` bigint(20) NOT NULL,
  `GrossWeight` decimal(10,2) NOT NULL,
  `Cone` decimal(10,2) NOT NULL,
  `TareWeight` decimal(10,2) NOT NULL,
  `NetWeight` decimal(10,2) NOT NULL,
  KEY `FK_PassNo` (`PassNo`),
  CONSTRAINT `FK_PassNo` FOREIGN KEY (`PassNo`) REFERENCES `GatePass` (`PassNo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `TransactionDetails` (
  `InvoiceNo` bigint(20) NOT NULL AUTO_INCREMENT,
  `ClientId` bigint(20) NOT NULL,
  `Date` date NOT NULL,
  `Quality` varchar(32) NOT NULL,
  `LotNo` varchar(32) NOT NULL,
  `Rate` decimal(10,2) NOT NULL,
  `HSNCode` varchar(32) NOT NULL,
  PRIMARY KEY (`InvoiceNo`),
  KEY `FK_ClientId` (`ClientId`),
  CONSTRAINT `FK_ClientId` FOREIGN KEY (`ClientId`) REFERENCES `ClientDetails` (`ClientId`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE `TransactionSubDetails` (
  `InvoiceNo` bigint(20) NOT NULL,
  `ChallanNo` bigint(20) NOT NULL,
  `NetWeight` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE DEFINER=`veggie_b2b`@`%` PROCEDURE `UspClientDetails`(
	IN `p_Condition` INT, 
    IN `p_Address` VARCHAR(1024),
    IN `p_FullName` VARCHAR(50),
    IN `p_GSTIN` VARCHAR(32),
    IN `p_State` VARCHAR(32),
    IN `p_PinCode` BIGINT,
    IN `p_ClientId` BIGINT
)
BEGIN
	IF p_Condition = 1 THEN
    BEGIN
		IF p_ClientId = 0 THEN
        BEGIN
			INSERT INTO ClientDetails
			(
				FullName,
				Address,
				GSTIN,
				State,
				PinCode
			)
			SELECT
				p_FullName,
				p_Address,
				p_GSTIN,
				p_State,
				p_PinCode;
		END;
        ELSE
        BEGIN
			UPDATE ClientDetails
            SET
				FullName = p_FullName,
				Address = p_Address,
				GSTIN = p_GSTIN,
				State = p_State,
				PinCode = p_PinCode
			WHERE ClientId = p_ClientId;
        END;
        END IF;
	END;
    END IF;
    IF p_Condition = 2 THEN
    BEGIN
		SELECT * FROM ClientDetails;
    END;
    END IF;
    IF p_Condition = 3 THEN
    BEGIN
		DELETE FROM ClientDetails
        WHERE ClientId = p_ClientId;
    END;
    END IF;
END


CREATE DEFINER=`veggie_b2b`@`%` PROCEDURE `UspGatePass`(
    IN `p_Condition` INT, 
    IN `p_Date` DATE,
    IN `p_FullName` VARCHAR(50),
    IN `p_LotNo` VARCHAR(32),
    IN `p_Quality` VARCHAR(32),
    IN `p_ToPerson` VARCHAR(50),
    IN `p_ChallanNo` INT,
    IN `p_PassNo` INT
)
BEGIN
	IF p_Condition = 1 THEN
    BEGIN
		INSERT INTO GatePass
        (
			FullName,
            Date,
            LotNo,
            Quality,
            ToPerson,
            ChallanNo
        )
        SELECT
			p_FullName,
            p_Date,
            p_LotNo,
            p_Quality,
            p_ToPerson,
            p_ChallanNo;
            
		SELECT last_insert_id();
	END;
    END IF;
    IF p_Condition = 2 THEN
    BEGIN
		SELECT IFNULL(MAX(ChallanNo), 0) ChallanNo
        FROM GatePass
        WHERE FullName = p_FullName;
    END;
    END IF;
    IF p_Condition = 3 THEN
    BEGIN
		SELECT GP.PassNo, FullName, LotNo, ChallanNo, Quality, Date, ToPerson, 
			Cone, GrossWeight, TareWeight, NetWeight
        FROM GatePass GP
        INNER JOIN SlipDetails SD ON GP.PassNo = SD.PassNo
        WHERE GP.PassNo = p_PassNo;
    END;
    END IF;
    IF p_Condition = 4 THEN
    BEGIN
		UPDATE GatePass SET
			Date = p_Date,
            ToPerson = FullName,
            LotNo = p_LotNo,
            Quality = p_Quality
        WHERE FullName = p_FullName
			AND ChallanNo = p_ChallanNo;
            
		SET @PassNo := 0;
		SELECT @PassNo := PassNo FROM GatePass
		WHERE FullName = p_FullName
			AND ChallanNo = p_ChallanNo;
            
		DELETE FROM SlipDetails
        WHERE PassNo = @PassNo;
        
        SELECT @PassNo;
    END;
    END IF;
    IF p_Condition = 5 THEN
    BEGIN
		SET @PassNo := 0;
		SELECT @PassNo := PassNo FROM GatePass
		WHERE FullName = p_FullName
			AND ChallanNo = p_ChallanNo;
        
		DELETE FROM GatePass
        WHERE FullName = p_FullName
			AND ChallanNo = p_ChallanNo;
            
		DELETE FROM SlipDetails
        WHERE PassNo = @PassNo;
    END;
    END IF;
    IF p_Condition = 6 THEN
    BEGIN
		SELECT * FROM GatePass
        WHERE FullName = p_FullName
			AND ChallanNo = p_ChallanNo;
		
        SET @row_num = 0;
		SELECT (@row_num := @row_num + 1) AS SlipNo, SD.* 
        FROM SlipDetails SD
        INNER JOIN GatePass GP ON GP.PassNo = SD.PassNo
        WHERE FullName = p_FullName
			AND ChallanNo = p_ChallanNo;
	END;
    END IF;
END


CREATE DEFINER=`veggie_b2b`@`%` PROCEDURE `UspLoginUser`(
	IN `p_CondOper` INT, 
    IN `p_UserName` VARCHAR(32),
    IN `p_Password` VARCHAR(32)
)
BEGIN
	IF p_CondOper = 1 THEN
    BEGIN
		SELECT 1 FROM LoginUser
        WHERE UserName = p_UserName AND Password = p_Password;
	END;
    END IF;
    IF p_CondOper = 2 THEN
    BEGIN
		INSERT INTO LoginUser
        (
			UserName,
            Password
        )
        SELECT
			p_UserName,
            p_Password;
    END;
    END IF;
    IF p_CondOper = 3 THEN
    BEGIN
		UPDATE LoginUser SET Password = p_Password
        WHERE UserName = p_UserName;
    END;
    END IF;
    IF p_CondOper = 4 THEN
    BEGIN
		SELECT 1 FROM LoginUser
        WHERE UserName = p_UserName;
    END;
    END IF;
END


CREATE DEFINER=`veggie_b2b`@`%` PROCEDURE `UspTransactionDetails`(
	IN `p_Condition` INT, 
    IN `p_Date` DATE,
    IN `p_FullName` VARCHAR(50),
    IN `p_LotNo` VARCHAR(32),
    IN `p_Quality` VARCHAR(32),
    IN `p_InvoiceNo` INT,
    IN `p_Rate` DECIMAL(10,2),
    IN `p_HSNCode` VARCHAR(32)
)
BEGIN
	IF p_Condition = 1 THEN
    BEGIN
		IF p_InvoiceNo = 0 THEN
		BEGIN
			INSERT INTO TransactionDetails
			(
				ClientId,
				Date,
				LotNo,
				Quality,
				Rate,
				HSNCode
			)
			SELECT
				(SELECT ClientId FROM ClientDetails WHERE FullName = p_FullName),
				p_Date,
				p_LotNo,
				p_Quality,
				p_Rate,
				p_HSNCode;
				
			SELECT last_insert_id();
		END;
        ELSE
        BEGIN
			UPDATE TransactionDetails
            SET ClientId = (SELECT ClientId FROM ClientDetails WHERE FullName = p_FullName),
				Date = p_Date,
				LotNo = p_LotNo,
				Quality = p_Quality,
				Rate = p_Rate,
				HSNCode = p_HSNCode
			WHERE InvoiceNo = p_InvoiceNo;
            
            DELETE FROM TransactionSubDetails WHERE InvoiceNo = p_InvoiceNo;
            
            SELECT p_InvoiceNo;
        END;
        END IF;
	END;
    END IF;
    IF p_Condition = 2 THEN
    BEGIN
		SELECT GSTIN FROM ClientDetails WHERE FullName = p_FullName;
    END;
    END IF;
    IF p_Condition = 3 THEN
    BEGIN
		SELECT CONVERT(GP.InvoiceNo, CHAR(32)) InvoiceNo, FullName, Address, GSTIN, State, 
			CONVERT(PinCode, CHAR(32)) PinCode, LotNo, Quality, 
			DATE_FORMAT(Date, "%d/%m/%Y") Date,
			ChallanNo, NetWeight, Rate, HSNCode
        FROM TransactionDetails GP
        INNER JOIN TransactionSubDetails SD ON GP.InvoiceNo = SD.InvoiceNo
        INNER JOIN ClientDetails CD ON CD.ClientId = GP.ClientId
        WHERE GP.InvoiceNo = p_InvoiceNo;
    END;
    END IF;
    IF p_Condition = 4 THEN
    BEGIN
		SELECT DISTINCT FullName FROM ClientDetails;
    END;
    END IF;
    IF p_Condition = 5 THEN
    BEGIN
		DELETE FROM TransactionSubDetails WHERE InvoiceNo = p_InvoiceNo;
        DELETE FROM TransactionDetails WHERE InvoiceNo = p_InvoiceNo;
    END;
    END IF;
    IF p_Condition = 6 THEN
    BEGIN
        SELECT FullName, LotNo, Quality, Rate, HSNCode, Date
        FROM TransactionDetails T
        INNER JOIN ClientDetails C ON T.ClientId = C.ClientId
        WHERE InvoiceNo = p_InvoiceNo;
        
        SELECT * FROM TransactionSubDetails WHERE InvoiceNo = p_InvoiceNo;
    END;
    END IF;
END