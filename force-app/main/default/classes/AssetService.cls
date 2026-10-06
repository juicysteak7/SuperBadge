@RestResource(urlMapping='/lost')
global with sharing class AssetService {
    @HttpPost global static String reportLostDevice(String assetIdentifier) {
        if(String.isBlank(assetIdentifier)) {
            return 'No device found.';
        }

        List<Asset> assets = [
            SELECT Id, Asset_Identifier__c, Status 
            FROM Asset
            WHERE Asset_Identifier__c = :assetIdentifier LIMIT 1];

        if(assets.isEmpty()) {
            return 'No device found.';
        }

        Asset asset = assets[0];
        asset.Status = 'Lost';
        update asset;

        List<Insurance__c> insurances = [
            SELECT Id
            FROM Insurance__c 
            WHERE Asset__c = :asset.Id
            AND Active__c = true
            AND Coverage__c = 'Comprehensive'
            LIMIT 1
            ];

        if(insurances.isEmpty()) {
            return 'No coverage. Asset status adjusted to Lost.';
        }

        List<Claim__c> claims = [
            SELECT Name
            FROM Claim__c 
            WHERE Asset__c = :asset.Id 
            AND Type__c = 'Loss'
            LIMIT 1
        ];

        if(!claims.isEmpty()) {
            return claims[0].Name + ' already filed.';
        }

        Claim__c newClaim = new Claim__c(
            Asset__c = asset.Id,
            Type__c = 'Loss',
            Insurance__c = insurances.isEmpty() ? null : insurances[0].Id
        );

        insert newClaim;

        return [SELECT Name FROM Claim__c WHERE Id = :newClaim.Id].Name;
    }
}