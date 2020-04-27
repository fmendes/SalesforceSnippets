/******************************************************************************
* Purpose: Test Method to test the Visualforce Page and Controller class
***************************************************************************************************************************/


@isTest
private class VFC_GeoNearbyAccounts_Test {

    // Test Method to test the data in the VF controller
    static testMethod void myUnitTest() {

        // Create the current Account information with Address details so the map can pinpoint the current Account on the map
        // Create with the appropriate minimum data for the Nearby Accounts page to show the correct information
        Account currentAccount = new Account();
        currentAccount.Name = 'Current';
        currentAccount.BillingStreet = '405 E 23rd St';
        currentAccount.BillingCity = 'Austin';
        currentAccount.BillingState = 'TX';
        currentAccount.BillingCountry = 'US';
        currentAccount.BillingPostalCode = '78712';
        currentAccount.BillingLatitude = 30;
        currentAccount.BillingLongitude = -97;
        insert currentAccount;

        // Create a nearby Account with Address details so the map can pinpoint the this nearby Account on the map
        Account nearbyAccount = new Account();
        nearbyAccount.Name = 'Nearby';
        nearbyAccount.BillingStreet = '1100 Congress Ave';
        nearbyAccount.BillingCity = 'Austin';
        nearbyAccount.BillingState = 'TX';
        nearbyAccount.BillingCountry = 'US';
        nearbyAccount.BillingPostalCode = '78701';
        nearbyAccount.BillingLatitude = 30;
        nearbyAccount.BillingLongitude = -97;
        nearbyAccount.Industry='Communications';
        insert nearbyAccount;

        PageReference pageRef = Page.GeoNearbyAccounts;
        pageRef.getParameters().put('Id',currentAccount.Id);

        Test.setCurrentPage(pageRef);
        ApexPages.StandardController con = new ApexPages.StandardController(currentAccount);
        VFC_GeoNearbyAccounts controller = new VFC_GeoNearbyAccounts(con);

        // System assert to show that a nearby Account has been found, testing controller
        System.assertEquals(1,controller.getNearbyAccounts().size());

        // Added extra lines to gain test coverage
        controller.filterFields='Industry:Type';
        controller.getNearbyAccounts();
        controller.submit(); // Test coverage

        //Just for more test coverage cover the zoomlevels
        controller.setZoomLevels(1);
        controller.setZoomLevels(5);
        controller.setZoomLevels(10);
        controller.setZoomLevels(20);
        controller.setZoomLevels(50);
        controller.setZoomLevels(100);
    }

/*
    // Test method - Code coverage when checking if the Account has no longitude or latitude details
    static testMethod void noLatitudeLongitudeTest() {


        // Create the current Account information with Address details so the map can pinpoint the current Account on the map
        // Create with the appropriate minimum data for the Nearby Accounts page to show the correct information
        Account currentAccount = new Account();
        currentAccount.Name = 'Current';
        currentAccount.BillingStreet = '405 E 23rd St';
        currentAccount.BillingCity = 'Austin';
        currentAccount.BillingState = 'TX';
        currentAccount.BillingCountry = 'US';
        currentAccount.BillingPostalCode = '78712';
        currentAccount.BillingLatitude = null;
        currentAccount.BillingLongitude = null;
        insert currentAccount;

        // Create a nearby Account with Address details so the map can pinpoint the this nearby Account on the map
        Account nearbyAccount = new Account();
        nearbyAccount.Name = 'Nearby';
        nearbyAccount.BillingStreet = '1100 Congress Ave';
        nearbyAccount.BillingCity = 'Austin';
        nearbyAccount.BillingState = 'TX';
        nearbyAccount.BillingCountry = 'US';
        nearbyAccount.BillingPostalCode = '78701';
        nearbyAccount.Industry='Communications';
        nearbyAccount.BillingLatitude = null;
        nearbyAccount.BillingLongitude = null;
        insert nearbyAccount;

        PageReference pageRef = Page.GeoNearbyAccounts;
        pageRef.getParameters().put('Id',currentAccount.Id);

        Test.setCurrentPage(pageRef);
        ApexPages.StandardController con = new ApexPages.StandardController(currentAccount);
        VFC_GeoNearbyAccounts controller = new VFC_GeoNearbyAccounts(con);

        // System assert to show that a nearby Account has been found, testing controller
        System.assertEquals(1,controller.getNearbyAccounts().size());

    }
*/
}