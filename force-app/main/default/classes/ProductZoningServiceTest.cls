@IsTest
private class ProductZoningServiceTest {
    private static final List<String> COUNTRIES = new List<String>{ 'US', 'AU', 'DE', 'FR' };

    // Simulates a GET call to the REST endpoint
    private static String callService(String productCode, String countryCode) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning/';
        req.httpMethod = 'GET';
        if (productCode != null) {
            req.params.put('ProductCode', productCode);
        }
        if (countryCode != null) {
            req.headers.put('CountryCode', countryCode);
        }
        RestContext.request = req;
        RestContext.response = new RestResponse();
        return ProductZoningService.getPermissibleFlyZone();
    }

    private static Product2 createProduct(String code, String family) {
        Product2 p = new Product2(Name = 'Test ' + code, ProductCode = code, Family = family, IsActive = true);
        insert p;
        return p;
    }

    @IsTest
    static void testPermissibleFlyZone() {
        // Use an existing metadata record (custom metadata is visible in tests)
        Product_Geo_Mapping__mdt mapping = [
            SELECT Country_Code__c, Product_Family__c, Permissible_Fly_Zone__c
            FROM Product_Geo_Mapping__mdt
            LIMIT 1
        ];
        createProduct('TEST-ZONE', mapping.Product_Family__c);

        Test.startTest();
        String result = callService('TEST-ZONE', mapping.Country_Code__c);
        Test.stopTest();

        Assert.areEqual(mapping.Permissible_Fly_Zone__c, result);
    }

    @IsTest
    static void testDefaultsToUS() {
        Product_Geo_Mapping__mdt mapping = [
            SELECT Product_Family__c, Permissible_Fly_Zone__c
            FROM Product_Geo_Mapping__mdt
            WHERE Country_Code__c = 'US'
            LIMIT 1
        ];
        createProduct('TEST-US', mapping.Product_Family__c);

        Test.startTest();
        String result = callService('TEST-US', null); // no CountryCode header
        Test.stopTest();

        Assert.areEqual(mapping.Permissible_Fly_Zone__c, result);
    }

    @IsTest
    static void testConfirmWithLocalAuthorities() {
        // Build the set of mapped family|country pairs
        Set<String> mapped = new Set<String>();
        for (Product_Geo_Mapping__mdt m : [
            SELECT Country_Code__c, Product_Family__c FROM Product_Geo_Mapping__mdt
        ]) {
            mapped.add(m.Product_Family__c + '|' + m.Country_Code__c);
        }

        // Find a real Family picklist value + country with no mapping
        String family;
        String country;
        for (Schema.PicklistEntry pe : Product2.Family.getDescribe().getPicklistValues()) {
            for (String c : COUNTRIES) {
                if (!mapped.contains(pe.getValue() + '|' + c)) {
                    family = pe.getValue();
                    country = c;
                    break;
                }
            }
            if (family != null) break;
        }
        Assert.isNotNull(family, 'Expected at least one unmapped family/country combination');

        createProduct('TEST-LOCAL', family);

        Test.startTest();
        String result = callService('TEST-LOCAL', country);
        Test.stopTest();

        Assert.areEqual('Confirm with the local authorities', result);
    }

    @IsTest
    static void testMissingProductCode() {
        Test.startTest();
        String result = callService(null, 'US');
        Test.stopTest();

        Assert.areEqual('ProductCode is missing or doesn\'t exist', result);
    }

    @IsTest
    static void testNonexistentProductCode() {
        Test.startTest();
        String result = callService('DOES-NOT-EXIST', 'DE');
        Test.stopTest();

        Assert.areEqual('ProductCode is missing or doesn\'t exist', result);
    }
}