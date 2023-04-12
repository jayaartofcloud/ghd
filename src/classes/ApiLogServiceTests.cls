/**
 * Created by Jayakumar Mogenahall on 04/04/2023.
 */

@IsTest
public  class ApiLogServiceTests {

    @IsTest
    static void apiLogWithResponseWrapper(){
        Test.startTest();
        RestResponseWrapper wrapper = new RestResponseWrapper();
        List<RestResponseWrapper> wrapperList = new List<RestResponseWrapper>();
        wrapper.data = null;
        wrapper.result = null;
        wrapperList.add(wrapper);
        ApiLogService.ApiLog('1234','400',wrapperList,'Test');
        Test.stopTest();

    }

    @IsTest
    static void apiLog(){
        Test.startTest();
        ApiLogService.ApiLog('1234','400','SomethingWentWrong','Test');
        Test.stopTest();
    }
}