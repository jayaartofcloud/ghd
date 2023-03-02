/**
 * Created by Jayakumar Mogenahall on 07/02/2023.
 */
@RestResource(UrlMapping='/Material/*')
global class MaterialProcess {

    static List<String> errorFieldsMap = new List<String>();
    static Boolean hasErrors = false;
    @HttpPut
    global static void doPut(){
        System.debug('#RestResponseWrapper');
        RestRequest req = RestContext.request;
        RestResponse res1 = RestContext.response;
        List<RestResponseWrapper>  resList = new List<RestResponseWrapper>();
        RestResponseWrapper res;
        MaterialRequestListWrapper matWrapper =  MaterialRequestWrapper.parse(req.requestBody.toString());
        System.debug('--1');
        System.debug('--matWrapper:'+matWrapper);
        for(MaterialRequestWrapper wrap: matWrapper.wrappers){
            if (String.isBlank(wrap.materialDescription)) {
                hasErrors = true;
                errorFieldsMap.add('material.materialDescription');
            }
            if (String.isBlank(wrap.productType)) {
                hasErrors = true;
                errorFieldsMap.add('material.productType');
            }
            if (String.isBlank(wrap.uom)) {
                hasErrors = true;
                errorFieldsMap.add('material.uom');
            }
            if (String.isBlank(wrap.owner)) {
                hasErrors = true;
                errorFieldsMap.add('material.owner');
            }
            if (String.isBlank(wrap.serialisedProduct)) {
                hasErrors = true;
                errorFieldsMap.add('material.serialisedProduct');
            }
            if (wrap.dangerousGoodsFlag == null) {
                hasErrors = true;
                errorFieldsMap.add('material.dangerousGoodsFlag');
            }
            if (wrap.carrierBag == null) {
                hasErrors = true;
                errorFieldsMap.add('material.carrierBag');
            }
            if (wrap.wetStock == null) {
                hasErrors = true;
                errorFieldsMap.add('material.wetStock');
            }
            if(wrap.origin == null || String.isBlank(wrap.origin?.originIdentifier)){
                hasErrors = true;
                errorFieldsMap.add('origin.originApplication');
            }
            if(wrap.origin == null ||String.isEmpty(wrap.origin?.originApplication)){
                hasErrors = true;
                errorFieldsMap.add('origin.originApplication');
            }
            if(wrap.origin == null || String.isBlank(wrap.origin.countryCode)){
                hasErrors = true;
                errorFieldsMap.add('origin.countryCode');
            }
            if (String.isBlank(wrap.dimensions.dimType)) {
                errorFieldsMap.add('dimension.dimType');
                hasErrors = true;
            }
            if (wrap.dimensions?.weight == null || Decimal.valueOf(wrap.dimensions.weight) <= 0) {
                errorFieldsMap.add('dimension.weight');
                hasErrors = true;
            }
            System.debug('#errorS: '+errorFieldsMap);
            System.debug('--2 has errors:' + hasErrors);
            if(hasErrors){
                String error;
                res = new RestResponseWrapper();
                res.result = 'Error';
                for(String f : errorFieldsMap){
                    String err = f;
                    error += err +',';
                }
                RestResponseWrapper.ErrorWrapper errorWrapper = new RestResponseWrapper.ErrorWrapper();
                errorWrapper.errorId = 123;
                errorWrapper.errorText = error.removeStart('null').removeEnd(',') +' can\'t be blank';
                res.error = errorWrapper;
                System.debug('#JSON.serialize(res):'+JSON.serialize(res));
                res1.responseBody = Blob.valueOf(JSON.serialize(res));
                res1.addHeader('Content-Type', 'application/json');
                res1.statusCode = 400;
                //return res1;
            }else{
                hasErrors = false;
            }

        }
        System.debug('--31');
        //find how many new and old records, using origin Identifier field
        //1. Collect all the OriginIdentifier
        Set<String> originIdentifiers = new Set<String>();
        Map<String, MaterialRequestWrapper> matWrapperMap = new Map<String,MaterialRequestWrapper>();
        for(MaterialRequestWrapper wrapper : matWrapper.wrappers){
            if(wrapper != null && wrapper?.origin != null && wrapper.origin?.originIdentifier != null){
                originIdentifiers.add(wrapper.origin.originIdentifier);
                matWrapperMap.put(wrapper.origin.originIdentifier, wrapper);
            }
        }
        System.debug('--4');
        List<Origin__c> originsToInsert = new List<Origin__c>();
        if(originIdentifiers.size() > 0 ){ // origin already exists
            List<Origin__c> origins = [SELECT Id, Identifier__c,Application__c,Country_Code__c FROM Origin__c WHERE Identifier__c IN : originIdentifiers];
            Set<String> identifiersIds = new Set<String>();
            Map<String, Origin__c> originMap2 = new Map<String,Origin__c>();
            for(Origin__c o : origins){
                identifiersIds.add(o.Id);
                originMap2.put(o.Identifier__c,o);
            }

            List<Material__c> materialList = [SELECT Id FROM Material__c WHERE Origin__c IN : identifiersIds ];

            if(materialList.size() > 0)
            {
                //already exists, so update action
            }
            else{
                //not exists, so insert action
                //1. insert origin
                for(String key : matWrapperMap.keySet()){
                    MaterialRequestWrapper mrw = matWrapperMap.get(key);
                    Origin__c origin = originMap2.get(mrw.origin.originIdentifier);
                    if(origin == null){
                        Origin__c org = new Origin__c();
                        org.Identifier__c = mrw.origin.originIdentifier;
                        org.Application__c = mrw.origin.originApplication;
                        org.Country_Code__c = mrw.origin.countryCode;
                        originsToInsert.add(org);
                    }
                }
            }
        }
        List<Database.UpsertResult> results;
        if(originsToInsert.size() > 0){
            insert originsToInsert;
        }
        System.debug('@ originsToInsert:'+originsToInsert);
       List<Material__c> materialsToInsert =  buildMaterial(matWrapperMap.values());
        if(materialsToInsert.size() > 0){
            results = Database.upsert(materialsToInsert) ;
        }
        System.debug('@ materialsToInsert:'+materialsToInsert);
        Map<String,Material__c> materialMap = new Map<String,Material__c>();
        Set<Id> materialIds = new Set<Id>();
        for(Material__c mat : materialsToInsert){
            materialMap.put(mat.Origin__r.Identifier__c,mat);
            materialIds.add(mat.Id);
        }
        System.debug('@materialIds:'+materialIds);
        List<Material__c> upsertMaterials = [SELECT Id,Origin__r.Identifier__c FROM Material__c  WHERE Id IN : materialIds];
        System.debug('@upsertMaterials:'+upsertMaterials);
        Map<String,String> originMatMap = new Map<String,String>();
        for(Material__c m : upsertMaterials){
            originMatMap.put(m.Origin__r.Identifier__c,m.Id);
        }
        System.debug('@ originMatMap:'+originMatMap);

        for(MaterialRequestWrapper wrap : matWrapper.wrappers){
            if(wrap.origin != null){
                Material__c mat =   materialMap.get(wrap.origin.originIdentifier);
                String materialId =  originMatMap.get(wrap.origin.originIdentifier);
                system.debug('#wrap:'+wrap);
                buildChildObjects(wrap, materialId, wrap.origin.originIdentifier);
            }
        }
        System.debug('#hasErrors:'+hasErrors);
        if(!hasErrors){
            res = new RestResponseWrapper();
            res.result = 'OK';

            RestResponseWrapper.Data idsData = new RestResponseWrapper.Data();
            String outputData;
            for(Database.UpsertResult result : results){
                outputData  += result.getId() + ',';
            }
            idsData.genericId = outputData.removeStart('null').removeEnd(',');
            res.data = idsData;
            res1.statusCode = 200;
            res1.responseBody = Blob.valueOf(JSON.serialize(res1));
        }
        //return res;
    }

    private static void buildChildObjects(MaterialRequestWrapper wrapper, String materialId, String originIdentifier){
        try {
            Material__c material = [SELECT Additional_Info__c,Region__c,Codes__c,Dimension__c FROM Material__c WHERE Id =: materialId];

            List<Dimension__c> dimensionRecord = new List<Dimension__c>();
            dimensionRecord = [SELECT Id FROM Dimension__c WHERE Material__c = :materialId LIMIT 1];
            System.debug('--1');
            if (dimensionRecord.size() > 0) {
                dimensionRecord[0].DimType__c = wrapper.dimensions.dimType;
                dimensionRecord[0].Weight__c = Integer.valueOf(wrapper.dimensions.weight);
                dimensionRecord[0].Height__c =  Integer.valueOf(wrapper.dimensions.height);
                dimensionRecord[0].Width__c =  Integer.valueOf(wrapper.dimensions.width);
                dimensionRecord[0].Depth__c =  Integer.valueOf(wrapper.dimensions.depth);
                dimensionRecord[0].Volume__c =  Integer.valueOf(wrapper.dimensions.volume);
                dimensionRecord[0].Total_Cartoon_In_Pallet__c =  Integer.valueOf(wrapper.dimensions.totalCartonInPallet);
                dimensionRecord[0].Total_Units_In_Cartoon__c =  Integer.valueOf(wrapper.dimensions.totalUnitsInCarton);
                dimensionRecord[0].Total_Units_In_Pallet__c =  Integer.valueOf(wrapper.dimensions.totalUnitsInPallet);
                dimensionRecord[0].Total_Units_In_Retail__c =  Integer.valueOf(wrapper.dimensions.totalUnitsInRetail);
                dimensionRecord[0].Material__c  = materialId;
                update dimensionRecord;
                System.debug('@ dimensionRecord update:'+dimensionRecord);
            } else {
                Dimension__c dimRec = new Dimension__c();
                dimRec.DimType__c = wrapper.dimensions.dimType;
                dimRec.Weight__c =  Integer.valueOf(wrapper.dimensions.weight);
                dimRec.Height__c =  Integer.valueOf(wrapper.dimensions.height);
                dimRec.Width__c =  Integer.valueOf(wrapper.dimensions.width);
                dimRec.Depth__c =  Integer.valueOf(wrapper.dimensions.depth);
                dimRec.Volume__c =  Integer.valueOf(wrapper.dimensions.volume);
                dimRec.Total_Cartoon_In_Pallet__c =  Integer.valueOf(wrapper.dimensions.totalCartonInPallet);
                dimRec.Total_Units_In_Cartoon__c =  Integer.valueOf(wrapper.dimensions.totalUnitsInCarton);
                dimRec.Total_Units_In_Pallet__c =  Integer.valueOf(wrapper.dimensions.totalUnitsInPallet);
                dimRec.Total_Units_In_Retail__c =  Integer.valueOf(wrapper.dimensions.totalUnitsInRetail);
                dimRec.Material__c = materialId;

                System.debug('@dimRec:'+dimRec);
                insert dimRec;
                material.Dimension__c = dimRec.Id;
                System.debug('@ dimensionRecord insert:'+dimRec);
            }
            System.debug('--2');
            List<Codes__c> codes = new List<Codes__c>();
            codes = [SELECT Id, Ean_Code__c, outer_EAN__c, ITF_Code__c, TARI_Code__c, Material__c FROM Codes__c WHERE Material__c = :materialId LIMIT 1];
            if (codes.size() > 0) {
                codes[0].Ean_Code__c = wrapper.codes.eanCode;
                codes[0].outer_EAN__c = wrapper.codes.outerEAN;
                codes[0].ITF_Code__c = wrapper.codes.itfCode;
                codes[0].TARI_Code__c = wrapper.codes.taricCode;
                codes[0].Material__c  = materialId;
                update codes;
                System.debug('#codes update:' + codes);
            } else {
                Codes__c codes1 = new Codes__c();
                codes1.Ean_Code__c = wrapper.codes.eanCode;
                codes1.outer_EAN__c = wrapper.codes.outerEAN;
                codes1.ITF_Code__c = wrapper.codes.itfCode;
                codes1.TARI_Code__c = wrapper.codes.taricCode;
                codes1.Material__c = materialId;
                System.debug('@codes1:'+codes1);
                insert codes1;
                material.Codes__c = codes1.Id;
                System.debug('#codes1 insert:' + codes1);
            }
            System.debug('--3');
            List<Region__c> regions;
            regions = [SELECT Id, Country_Code__c, Regional_Description__c, Material__c from Region__c WHERE Material__c = :materialId LIMIT 1];
            if (regions.size() > 0) {
                regions[0].Country_Code__c = wrapper.region.countryCode;
                regions[0].Regional_Description__c = wrapper.region.regionalDescription;
                regions[0].Material__c = materialId;
                update regions;
                System.debug('#regions update:' + regions);
            } else {
                Region__c region = new Region__c();
                region.Country_Code__c = wrapper.region.countryCode;
                region.Regional_Description__c = wrapper.region.regionalDescription;
                region.Material__c = materialId;
                System.debug('@region:'+region);
                insert region;
                material.Region__c = region.Id;
                System.debug('#regions insert:' + region);
            }
            System.debug('--4');
            List<Additional_Info__c> additionalInfos;
            additionalInfos = [SELECT Id, Info1__c, Info2__c, Info3__c, Info4__c, Info5__c FROM Additional_Info__c WHERE Material__c = :materialId LIMIT 1];
            if (additionalInfos.size() > 0) {
                additionalInfos[0].Info1__c = wrapper.additionalInfo.info1;
                additionalInfos[0].Info2__c = wrapper.additionalInfo.info2;
                additionalInfos[0].Info3__c = wrapper.additionalInfo.info3;
                additionalInfos[0].Info4__c = wrapper.additionalInfo.info4;
                additionalInfos[0].Info5__c = wrapper.additionalInfo.info5;
                additionalInfos[0].Material__c  = materialId;
                update additionalInfos;
                System.debug('#additionalInfos update:' + additionalInfos);
            } else {
                Additional_Info__c additionalInfo = new Additional_Info__c();
                additionalInfo.Info1__c = wrapper.additionalInfo.info1;
                additionalInfo.Info2__c = wrapper.additionalInfo.info2;
                additionalInfo.Info3__c = wrapper.additionalInfo.info3;
                additionalInfo.Info4__c = wrapper.additionalInfo.info4;
                additionalInfo.Info5__c = wrapper.additionalInfo.info5;
                additionalInfo.Material__c = materialId;
                System.debug('@additionalInfo:'+additionalInfo);
                insert additionalInfo;
                material.Additional_Info__c = additionalInfo.Id;
                System.debug('#additionalInfos insert:' + additionalInfo);
            }
            update material;
            System.debug('--5');
//        Origin__c origin;
//        origin = [SELECT Id,Application__c,Identifier__c,Country_Code__c,Material__c FROM Origin__c WHERE Identifier__c =: wrapper.origin.originIdentifier ];
//        if(origin != null){
//            origin.Application__c = wrapper.origin.originApplication;
//            origin.Identifier__c = wrapper.origin.originIdentifier;
//            origin.Country_Code__c = wrapper.origin.countryCode;
//            update origin;
//        }else{
//            origin = new Origin__c();
//            origin.Application__c = wrapper.origin.originApplication;
//            origin.Identifier__c = wrapper.origin.originIdentifier;
//            origin.Country_Code__c = wrapper.origin.countryCode;
//            origin.Material__c = materialId;
//            insert origin;
//        }
        }
        catch (Exception ex){
            System.debug('ERROR Material Process:' + ex.getMessage() + '-> ' + ex.getStackTraceString());
        }
    }


    private static List<Material__c> buildMaterial(List<MaterialRequestWrapper> wrappers){

        Set<String> originIdentifiers = new Set<String>();
        for(MaterialRequestWrapper wrapper: wrappers){
            if(wrapper.origin?.originIdentifier != null){
                originIdentifiers.add(wrapper.origin.originIdentifier);
            }
        }

        List<Origin__c> origins = [SELECT Id,Identifier__c,Application__c,Country_Code__c FROM Origin__c WHERE Identifier__c IN : originIdentifiers];
        Map<String,Origin__c> originMap = new Map<String,Origin__c>();
        for(Origin__c origin: origins){
            originMap.put(origin.Identifier__c,origin);
        }

        Set<String> originIds = new Set<String>();
        for(MaterialRequestWrapper wrapper : wrappers){
            if(wrapper.origin != null){
                originIds.add(wrapper.origin?.originIdentifier);
            }
        }


        Map<String,MaterialRequestWrapper> wrapperMap = new Map<String,MaterialRequestWrapper>();
        for(MaterialRequestWrapper wrapper : wrappers){
            wrapperMap.put(wrapper.origin.originIdentifier,wrapper);
        }


        System.debug('#originIds:'+originIds);
        List<Material__c> materialList = [SELECT Id,Bundle__c,Carrier_Bag__c,Category__c,Customs_Description__c,Dangerous_Goods_Flag__c,
                Dangerous_Goods_Classification__c,Dangerous_Goods_Packing_Group__c,Dangerous_Goods_Shipping_Name__c,
                Inventory__c,Is_Active__c,Is_TNT_Enabled__c,Kit_Date__c,Material_Description__c,Owner__c,Product_Type__c,
                Replacement_Code__c,Serialised_Product__c,Start_Date__c,Units__c,UOM__c,Wet_Stock__c,Origin__r.Identifier__c
        FROM Material__c WHERE Origin__r.Identifier__c IN : originIds];
        List<Material__c> materialsList = new List<Material__c>();
        System.debug('#1 materialList:'+materialList);
        if(materialList.size() == 0){
            for(MaterialRequestWrapper wrapper : wrappers){
                Material__c material = new Material__c();
                material.Bundle__c = wrapper.bundle;
                material.Carrier_Bag__c = wrapper.carrierBag;
                material.Category__c = wrapper.category;
                material.Customs_Description__c = wrapper.customsDescription;
                material.Dangerous_Goods_Shipping_Name__c = wrapper.dangerousGoodsShippingName;
                material.Dangerous_Goods_Packing_Group__c = wrapper.dangerousGoodsPackingGroup;
                material.Dangerous_Goods_Classification__c = wrapper.dangerousGoodsClassification;
                material.Dangerous_Goods_Flag__c = false;//wrapper.dangerousGoodsFlag;
                material.Inventory__c = wrapper.inventory;
                material.Is_Active__c = false;
                material.Is_TNT_Enabled__c = false;
                material.Kit_Date__c = wrapper.kitDate;
                material.Wet_Stock__c = wrapper.wetStock;
                material.Material_Description__c = wrapper.materialDescription;
                material.Owner__c = wrapper.owner;
                material.Product_Type__c = wrapper.productType;
                material.Replacement_Code__c = wrapper.replacementCode;
                material.Serialised_Product__c = wrapper.serialisedProduct;
                material.Start_Date__c = wrapper.startDate;
                material.Units__c = wrapper.units;
                material.UOM__c = wrapper.uom;
                Origin__c origin = originMap.get(wrapper.origin.originIdentifier);
                material.Origin__c = origin.Id;
                materialsList.add(material);
            }
        }
        else {
            for(Material__c material: materialList){
                MaterialRequestWrapper wrapper = wrapperMap.get(material.Origin__r.Identifier__c);
                System.debug('#2 wrapper:'+wrapper);
                material.Bundle__c = wrapper.bundle;
                material.Carrier_Bag__c = wrapper.carrierBag;
                material.Category__c = wrapper.category;
                material.Customs_Description__c = wrapper.customsDescription;
                material.Dangerous_Goods_Shipping_Name__c = wrapper.dangerousGoodsShippingName;
                material.Dangerous_Goods_Packing_Group__c = wrapper.dangerousGoodsPackingGroup;
                material.Dangerous_Goods_Classification__c = wrapper.dangerousGoodsClassification;
                material.Dangerous_Goods_Flag__c = wrapper.dangerousGoodsFlag;
                material.Inventory__c = wrapper.inventory;
                material.Is_Active__c = false;//Boolean.valueOf(wrapper?.active);
                material.Is_TNT_Enabled__c = false;//Boolean.valueOf(wrapper?.tntEnabled);
                material.Kit_Date__c = wrapper.kitDate;
                material.Wet_Stock__c = wrapper.wetStock;
                material.Material_Description__c = wrapper.materialDescription;
                material.Owner__c = wrapper.owner;
                material.Product_Type__c = wrapper.productType;
                material.Replacement_Code__c = wrapper.replacementCode;
                material.Serialised_Product__c = wrapper.serialisedProduct;
                material.Start_Date__c = wrapper.startDate;
                material.Units__c = wrapper.units;
                material.UOM__c = wrapper.uom;
                System.debug('# Mt update :'+material);
                materialsList.add(material);
            }
        }

        return materialsList;
    }
}