@IsTest
private class AssetServiceTest {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Drone Customer');
        insert acct;

        List<Asset> assets = new List<Asset>{
            new Asset(Name = 'Covered Drone',   AccountId = acct.Id, Asset_Identifier__c = 'COVERED-001'),
            new Asset(Name = 'Uninsured Drone', AccountId = acct.Id, Asset_Identifier__c = 'NOCOVER-001'),
            new Asset(Name = 'Claimed Drone',   AccountId = acct.Id, Asset_Identifier__c = 'CLAIMED-001')
        };
        insert assets;

        List<Insurance__c> policies = new List<Insurance__c>{
            new Insurance__c(Asset__c = assets[0].Id, Coverage__c = 'Comprehensive', Active__c = true),
            new Insurance__c(Asset__c = assets[2].Id, Coverage__c = 'Comprehensive', Active__c = true)
        };
        insert policies;

        insert new Claim__c(Asset__c = assets[2].Id, Insurance__c = policies[1].Id, Type__c = 'Loss');
    }

    @IsTest
    static void blankIdentifierReturnsNoDevice() {
        Test.startTest();
        String result = AssetService.reportLostDevice('');
        Test.stopTest();
        Assert.areEqual('No device found.', result);
    }

    @IsTest
    static void unknownIdentifierReturnsNoDevice() {
        Test.startTest();
        String result = AssetService.reportLostDevice('DOES-NOT-EXIST');
        Test.stopTest();
        Assert.areEqual('No device found.', result);
    }

    @IsTest
    static void noCoverageMarksAssetLost() {
        Test.startTest();
        String result = AssetService.reportLostDevice('NOCOVER-001');
        Test.stopTest();

        Assert.areEqual('No coverage. Asset status adjusted to Lost.', result);
        Asset a = [SELECT Status FROM Asset WHERE Asset_Identifier__c = 'NOCOVER-001'];
        Assert.areEqual('Lost', a.Status);
    }

    @IsTest
    static void comprehensiveCoverageCreatesClaim() {
        Test.startTest();
        String result = AssetService.reportLostDevice('COVERED-001');
        Test.stopTest();

        Claim__c claim = [
            SELECT Name, Type__c FROM Claim__c
            WHERE Asset__r.Asset_Identifier__c = 'COVERED-001'
        ];
        Assert.areEqual(claim.Name, result);
        Assert.areEqual('Loss', claim.Type__c);

        Asset a = [SELECT Status FROM Asset WHERE Asset_Identifier__c = 'COVERED-001'];
        Assert.areEqual('Lost', a.Status);
    }

    @IsTest
    static void existingLossClaimReturnsAlreadyFiled() {
        Claim__c existing = [
            SELECT Name FROM Claim__c
            WHERE Asset__r.Asset_Identifier__c = 'CLAIMED-001'
        ];

        Test.startTest();
        String result = AssetService.reportLostDevice('CLAIMED-001');
        Test.stopTest();

        Assert.areEqual(existing.Name + ' already filed.', result);
        Assert.areEqual(1, [SELECT COUNT() FROM Claim__c WHERE Asset__r.Asset_Identifier__c = 'CLAIMED-001']);
    }
}