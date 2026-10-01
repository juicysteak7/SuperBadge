@RestResource(urlMapping='/ProductZoning/*')
global with sharing class ProductZoningService {
    @HttpGet
    global static String getPermissibleFlyZone() {
        RestRequest req = RestContext.request;

        String countryCode = req.headers.get('CountryCode');
        if (String.isBlank(countryCode)) {
            countryCode = 'US';
        }

        String productCode = req.params.get('ProductCode');
        if (String.isBlank(productCode)) {
            return 'ProductCode is missing or doesn\'t exist';
        }

        List<Product2> products = [
            SELECT Id, Name, ProductCode, Family
            FROM Product2
            WHERE ProductCode = :productCode
            LIMIT 1];

        if (products.isEmpty()) {
            return 'ProductCode is missing or doesn\'t exist';
        }

        String family = products[0].Family;

        List<Product_Geo_Mapping__mdt> mappings = [
            SELECT Id, Product_Family__c, Country_Code__c, Permissible_Fly_Zone__c 
            FROM Product_Geo_Mapping__mdt 
            WHERE Product_Family__c = :family AND Country_Code__c = :countryCode 
            LIMIT 1];

        if (mappings.isEmpty()) {
            return 'Confirm with the local authorities';
        }

        return mappings[0].Permissible_Fly_Zone__c;
    }
}