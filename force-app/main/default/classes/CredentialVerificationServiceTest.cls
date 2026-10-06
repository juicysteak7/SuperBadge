@IsTest
private class CredentialVerificationServiceTest {

    @TestSetup
    static void setup() {
        Contact pilot = new Contact(FirstName = 'Dana', LastName = 'Skyward');
        insert pilot;

        Certification__c cert = new Certification__c(Name = 'Commercial Drone License');
        insert cert;

        insert new List<Contact_Certification__c>{
            new Contact_Certification__c(Contact__c = pilot.Id, Certification__c = cert.Id,
                                        Issue_Date__c = Date.today(), isActive__c = true),
            new Contact_Certification__c(Contact__c = pilot.Id, Certification__c = cert.Id,
                                        Issue_Date__c = Date.today().addYears(-3), isActive__c = false)
        };

    }

    private static String certName(Boolean active) {
        return [SELECT Name FROM Contact_Certification__c WHERE isActive__c = :active LIMIT 1].Name;
    }

    @IsTest
    static void activeCertificationIsValid() {
        Assert.areEqual('Valid',
            CredentialVerificationService.verifyCredential('Skyward', certName(true)));
    }

    @IsTest
    static void inactiveCertificationNeedsRenewal() {
        Assert.areEqual('Needs Renewal',
            CredentialVerificationService.verifyCredential('Skyward', certName(false)));
    }

    @IsTest
    static void wrongLastNameReturnsNoRecord() {
        Assert.areEqual('No record found',
            CredentialVerificationService.verifyCredential('Nobody', certName(true)));
    }

    @IsTest
    static void wrongCertNameReturnsNoRecord() {
        Assert.areEqual('No record found',
            CredentialVerificationService.verifyCredential('Skyward', 'NOT-A-CERT'));
    }

    @IsTest
    static void blankInputsReturnNoRecord() {
        Assert.areEqual('No record found',
            CredentialVerificationService.verifyCredential('', certName(true)));
        Assert.areEqual('No record found',
            CredentialVerificationService.verifyCredential('Skyward', null));
    }
}