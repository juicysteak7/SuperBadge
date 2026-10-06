global with sharing class CredentialVerificationService {

    webservice static String verifyCredential(String lastName, String certificationName) {
        if (String.isBlank(lastName) || String.isBlank(certificationName)) {
            return 'No record found';
        }

        List<Contact_Certification__c> certs = [
            SELECT isActive__c
            FROM Contact_Certification__c
            WHERE Contact__r.LastName = :lastName
              AND Name = :certificationName
            LIMIT 1
        ];

        if (certs.isEmpty()) {
            return 'No record found';
        }

        return certs[0].isActive__c ? 'Valid' : 'Needs Renewal';
    }
}