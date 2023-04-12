/**
 * Created by Jayakumar Mogenahall on 02/02/2023.
 */
@IsTest
public with sharing class ValidationServiceTest {
    @IsTest
    static void Test1(){
        String json = '{"customerId":"12345","firstName":"Jaya","lastName":"JK","origin": {"originApplication":"testOriginApp"}, "additionalInfo": {"info1":"testInfo1"}}';

        ValidationService.validateRequestPayload('Account',json);
    }

}