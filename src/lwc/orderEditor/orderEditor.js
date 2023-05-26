/**
 * Created by Jayakumar Mogenahall on 14/02/2023.
 */

import { LightningElement,wire,track,api} from 'lwc';
import generateData from './generateData';
import productsDump from '@salesforce/apex/ProductsDump.buildProductDump';
import getOrderDraftByDescription from '@salesforce/apex/ProductsDump.getOrderDraftByDescription';
//import createDaft from '@salesforce/apex/ProductService.create';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';
import {loadStyle} from 'lightning/platformResourceLoader';
import dataTableStyles from '@salesforce/resourceUrl/dataTableStyles';
import getDraftViewForCustomer from '@salesforce/apex/OrderDraftService.getDraftViewForCustomer';
import createOrder from '@salesforce/apex/OrderService.createOrder';
import getMaterialsForAccount from '@salesforce/apex/CustomerProductService.getMaterialsForAccount';
import createDaft from '@salesforce/apex/CustomerProductService.create';
import {subscribe,publish,unsubscribe,APPLICATION_SCOPE,MessageContext} from 'lightning/messageService';
import promotionMessage from "@salesforce/messageChannel/promotionMessage__c";
import { NavigationMixin } from 'lightning/navigation';



const columns = [
    { label: 'Product Name', fieldName: 'ProductName', editable: false },
       { label: 'Category', fieldName: 'Category', type: 'string', editable: false, hideDefaultActions:"true" },
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', editable: false, hideDefaultActions:"true", typeAttributes:{currencyCode: 'GBP',variant:"Error"}, cellAttributes:{iconName:{fieldName:'iconName'}, iconClass:"slds-current-color",iconPosition:'right'}},
    { label: 'Order Qty', fieldName: 'OrderQty', type: 'number', editable: true, hideDefaultActions:"true" },
    { label: 'Free Qty', fieldName: 'FreeQty', type: 'number', editable: true, hideDefaultActions:"true" },
    { label: 'Promo Order Qty', fieldName: 'promoOrderQty', type: 'number', editable: true, hideDefaultActions:"true" },
    { label: 'Promo Free Qty', fieldName: 'promoFreeQty', type: 'number', editable: false, hideDefaultActions:"true",cellAttributes: { alignment: 'left' } },
];

const previewColumns = [
    { label: 'Product Name', fieldName: 'ProductName', editable: false },
       { label: 'Category', fieldName: 'Category', type: 'string', editable: false, hideDefaultActions:"true" },
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', editable: false, hideDefaultActions:"true", typeAttributes:{currencyCode: 'GBP',variant:"Error"}, cellAttributes:{iconName:{fieldName:'iconName'}, iconClass:"slds-current-color",iconPosition:'right'}},
    { label: 'Order Qty', fieldName: 'OrderQty', type: 'number', editable: false, hideDefaultActions:"true" },
    { label: 'Free Qty', fieldName: 'FreeQty', type: 'number', editable: false, hideDefaultActions:"true" },
    { label: 'Promo Order Qty', fieldName: 'promoOrderQty', type: 'number', editable: false, hideDefaultActions:"true" },
    { label: 'Promo Free Qty', fieldName: 'promoFreeQty', type: 'number', editable: false, hideDefaultActions:"true",cellAttributes: { alignment: 'left' } },
];

const draftColumns = [
	{ label: 'Draft Name', fieldName: 'DraftRecordName', editable: false,hideDefaultActions:"true"  },
	{label: 'Description', fieldName:'Description', editable: false,hideDefaultActions:"true"  },
	{ label: 'Total Value', fieldName: 'TotalAmount', type: 'currency', editable: false,hideDefaultActions:"true",  typeAttributes:{currencyCode: 'GBP'}},
	{label: 'Last Modified By', fieldName: 'LastModifiedBy', hideDefaultActions:"true", editable:false},
	{label: 'Last Modified Date', fieldName: 'LastModifiedDate',hideDefaultActions:"true",  editable:false}

];

export default class orderEditor extends NavigationMixin(LightningElement) {
	@api recordId;
	@track isShowModal = false;
	@track productNav = null;
	draftValues =[];
	data = [];
	masterData = [];
	columns = columns;
	previewColumns = previewColumns
	draftColumns = draftColumns;
	rowOffset = 0;
	selectedFamily = 'All';
	selectedOrderType = '';
	searchToken = '';
	family = '';
	wiredDataResult;
	@track totalAmount = 0.00;
	@api firstName = 'John Doe';
	selectedRowData;
	totalOrderQty=[];
	selectedOrders =[]
	allSelectedOrderQty = [];
	selectedProducts = [];
	errors;
	isShowViewDraftModal = false;
	staticResourceLoaded = false;
	preSelectedRows = 'a0L2z000000p9o0EAA'
	selectedDraftRowDescription;
	draftFieldValues = [];
	viewDraftScreenData = [];
	draftName;
	isShowDraftModelName = false;
	selectedRows = [];
	draftDescription;
	name;
	draftItemSelectedCount = 0;
	dataSpinner = true;
	start = true;
	orderPreview = false;
	canOrderPreview = false;
	totalInclVat = 0.00;
	totalExclVat = 0.00;
	selectedDate = '';
	selectedReference = '';
	selectedLaserText = '';
	showPersonalisation = false;
	showReplacement = false;
	showFree = false;
	canShowOrderConsole = true;
	canShowPromotion = false;
	categories = [];
	newMasterData = [];
	promoOrderQty = 0;
	freeQuantity = 0;
	productType= '';
	promotionExists = false;
	selectedPromoList = []
	qtyLeft = 0;
	selPromotionCopy = [];
	isPromotionOrderValid = false;
	totalPromoOrderQty = 0;
	message = {};
	previewProducts = [];
	orderQtyCount = 0;
  showErrorTab = false;
  errorMessage;
  messageType;
  testMessage=[];
  promotionToEdit=[];
  isOrderValid = true;
  @track disableSaveButton = true;
  disableSaveDraftButton = true;
  disableViewDraftButton = true;
  masterDraftValues=[];
  freeProducts = [];
  reference;
  deliveryDate;
  finalDraft = []
  orderQtyObj = []
  promoOrderCounts = []





	 subscription = null;
	 @api selectedPromotion = [];
	 promotionOrderCount;
 	newObj = {};


	@wire(MessageContext)
	messageContext;


	subSetResult = {"category":'', "data":[]}


	get categoryOptions() {
		return this.categories.map(item=> { return{label:item, value:item }} );
    }

     subscribeToMessageChannel() {

            if (!this.subscription) {
                this.subscription = subscribe(
                    this.messageContext,
                    promotionMessage,
                    (message) => this.handleSubscribe(message) ,
                    { scope: APPLICATION_SCOPE }
                );
            }
        }



	handleSubscribe(message){
		this.canShowPromotion = false;
//		console.log('###message:'+ JSON.stringify(message))
//		console.log('#message.selectedPromotion:'+message.selectedPromotion)
		//in case user cancelled from Preview order screen then we need to retain all values
		if(message.orderDraftValues.length > 0){
		    setTimeout(() => {
		          this.template.querySelector("[data-id='mainDatatable']").draftValues =  message.orderDraftValues.slice();
      		},0);
		    this.start = true;
		    this.canShowOrderConsole = true;
		    this.canShowPromotion = false;
  		}

		if(JSON.parse(message.selectedPromotion).length > 0 ){
		    this.selectedPromotion = JSON.stringify(JSON.parse(message.selectedPromotion));
		    this.promotionToEdit =  JSON.stringify(JSON.parse(message.selectedPromotion));;
		    this.promotionExists = true;
  		}else{

			this.promotionExists = false;
			this.selPromotionCopy = [];
			this.promotionToEdit= [];
			this.selectedPromotion = [];
    	}

		try{
		    if(this.promotionExists && this.selectedPromotion.length > 0){
		     //copy the promotion array
			this.selPromotionCopy = JSON.parse(this.selectedPromotion.slice());
		    if(this.selectedPromotion.length === 0) {
		        this.selPromotionCopy = [];
		        this.canShowOrderConsole = true;
				return;
		    }

			//Count total Promotion Order quantity
			this.totalPromoOrderQty =   this.selPromotionCopy.reduce((a,b) => a + b.OrderQuantity,0);
console.log('#this.selPromotionCopy:' + JSON.stringify( this.selPromotionCopy))
			 //set the promotion / free quantity to main data set
			 debugger
			 this.selPromotionCopy.forEach( promo => {
							const idx = this.newMasterData.findIndex(item => item.MaterialCode === promo.MaterialCode)
							this.data[idx].promoFreeQty = promo.FreeQuantity
							this.newMasterData[idx].promoFreeQty = promo.FreeQuantity
							//this.promoFreeQty = promo.FreeQuantity;
							this.productType =  promo.Category;
							 promo.qtyLeft = 0;
							promo.valid = '';
						 })
			}
			}
		catch(error){ alert(JSON.stringify('Error2:' + error))}
		 this.canShowOrderConsole = true;
	}

	unsubscribeToMessageChannel() {
		unsubscribe(this.subscription);
		this.subscription = null;
	}

	disconnectedCallback() {
			this.unsubscribeToMessageChannel();
	}
	get optionsType() {
        return [
            {label:'Standard Order',value:'B'},
            {label: 'Replacement Order', value:'R'},
            {label: 'Personalisation Order', value:'P'},
            {label: 'Free Order', value:'Free Order'},
        ];
    }



	@wire(getMaterialsForAccount, {accountId:'$recordId',searchToken:'$searchToken',draftName:''})
	wiredResult({error,data}){
	this.wiredDataResult = data;

	if(data){
			this.masterData = data;


			this.dataSpinner = false;
			//used to fill the dropdown list
			this.categories = data.categories;

			this.data = data.wrapperList.map(item=> { return{...item, OrderQty: "",promoFreeQty:"" }} );
			this.newMasterData = data.wrapperList.map(item=> { return{...item, OrderQty: "",promoFreeQty:""  }} );


		}
	else if(error){
		alert(JSON.stringify('Error xX:'+error));
	}
		if(data !== undefined && data === null){
			this.dataSpinner = false;
			this.showWarningToast('No materiels found for the customer');
			return;
		}
	}

	connectedCallback() {
	    const  icons =   this.template.querySelectorAll('lightning-icon[data-key="left"]')
	    loadStyle(this, dataTableStyles);
	    //subscribe to message channel
	    this.subscribeToMessageChannel();
	}

	handleProductCategoryChange(event){
		this.selectedFamily = event.detail.value;
		this.searchToken = '';
		this.template.querySelector("[data-id='searchField']").value = '';
		this.filterMaterials();
	}

	handleOrderTypeChange(event){
		this.selectedOrderType = event.detail.value; 
	}

	handleSearch(event){
		this.searchToken = event.target.value;
		this.filterMaterials();
	}

	validateDataTable(event){
	    if(this.selectedOrderType){
	        console.log('Please select Order Type.')
     	}
 	}

	handleOnCellChange(event){
		var qtySum = [];
		const draftValue = event.detail.draftValues;
//		console.log('# draftValue:' + JSON.stringify(draftValue))
//		console.log('# promotionExists :' + this.promotionExists )

console.log('## 1 ##')
	 	this.removeEmptyCellValue(draftValue)
		// this.addOrUpdateFields(draftValue)
		console.log('## 2 ##')
		this.calculateTotalAmount(draftValue,qtySum)
		console.log('## 3 ##')
		//this.updatePromotionQtyCount(draftValue)
		console.log('## 4 ##')
		this.countPromoQty(draftValue);
	}

	countPromoQty(draftValue){
	debugger
	if(this.selectedPromotion.length === 0){
	        return;
	 }

	     console.log('#0 orderQtyObj:' + JSON.stringify(this.orderQtyObj))
	    console.log('#0 draftValue:'+JSON.stringify(draftValue))
	    var masterRow = this.newMasterData.find(masterData => masterData.Id === draftValue[0].Id)
	    console.log('#0 masterRow' + JSON.stringify(masterRow))
	    var draftValueItemValues = Object.values(draftValue[0])
	    var draftValueItemKeys = Object.keys(draftValue[0])
	     var promoCategories = JSON.parse(this.selectedPromotion).map(item => item.Category)
	    if(draftValueItemKeys.includes('promoOrderQty') !== false){
	        console.log('#2draftValueItemValues:'+JSON.stringify(draftValueItemValues))

console.log('---A')
	            console.log('---B')
				var foundItem = this.orderQtyObj.find(x => x.Id === draftValue[0].Id);
				console.log('#foundItem:'+ JSON.stringify(foundItem))
				var foundItemIndex = this.orderQtyObj.findIndex(x => x.Id === draftValue[0].Id);
				console.log('#foundItemIndex:'+foundItemIndex)
				if(foundItem){
				    console.log('---C')
					this.orderQtyObj[foundItemIndex].promoOrderQty = draftValue[0].promoOrderQty
				}else{
				    console.log('---D')
				    this.orderQtyObj.push({Category: masterRow.Category, promoOrderQty: draftValue[0].promoOrderQty, Id:draftValue[0].Id})
   				 }
				console.log('---F this.orderQtyObj:'+JSON.stringify(this.orderQtyObj))

   		 }

			if(this.orderQtyObj.length > -1){

			    var categories = [...new Set(this.orderQtyObj.map(x => x.Category))]
			    console.log('#categories:'+categories)
			      console.log('#categories 1:'+ JSON.stringify(categories))
			    console.log('#categories is array:'+ Array.isArray(categories))
			    categories.forEach(cat => {
			        console.log('#cat:'+cat)
			        var filteredRows = this.orderQtyObj.filter(x => x.Category === cat && x.promoOrderQty !== "")
			        console.log('#filteredRows:'+JSON.stringify(filteredRows))

			        var xx = filteredRows.reduce((a,b) => a + parseInt(b.promoOrderQty),0);
			        console.log('#xx:'+JSON.stringify(xx))
			        console.log('this.promoOrderCounts is array:' + Array.isArray(this.promoOrderCounts))
					var foundItem = this.promoOrderCounts.find(x => x.Category === masterRow.Category)
					var foundItemIndex = this.promoOrderCounts.findIndex(x => x.Category === masterRow.Category)
					console.log('###-- 1')
					    if(foundItem){
					        	console.log('###-- 2')
					        this.promoOrderCounts[foundItemIndex].Count = xx
					        }
					     else{
					         var foundItem1 = this.promoOrderCounts.find(x => x.Category === cat)
					         if(!foundItem1){
					             console.log('###-- 3')
								this.promoOrderCounts.push({Category :cat , Count:xx })
             				 }

							}
								console.log('###-- 4')
      			})

			}
			console.log('#promoOrderCounts:'+JSON.stringify(this.promoOrderCounts))
debugger

			const testPromo = this.selPromotionCopy.slice()
			testPromo.map(x => {
			    console.log('#this.promoOrderCounts.find(a => a.Category == x.Category):'+ JSON.stringify(this.promoOrderCounts.find(a => a.Category == x.Category)))
			    if(JSON.stringify(this.promoOrderCounts.find(a => a.Category == x.Category)) !== undefined){
			        	if(this.promoOrderCounts.find(a => a.Category == x.Category).Count <= x.OrderQuantity){
			        	    console.log('x.OrderQuantity :'+x.OrderQuantity )
			        	    console.log('this.promoOrderCounts.find(a => a.Category == x.Category).Count):'+this.promoOrderCounts.find(a => a.Category == x.Category).Count)
			          		 x.qtyLeft =  this.promoOrderCounts.find(a => a.Category == x.Category).Count
			          		   this.isOrderValid = true;
			           }else{
			               this.isOrderValid = false;

							 var storedDraftValues = JSON.parse(JSON.stringify(this.template.querySelector("[data-id='mainDatatable']").draftValues))
							 var idx =  storedDraftValues.findIndex(x => x.Id == draftValue[0].Id)
                             		    let item =  storedDraftValues.find(x => x.Id === draftValue[0].Id)
                             			if(item){
                             				var keys = Object.keys(item)
                             				if(keys.includes('promoOrderQty') && keys.includes("OrderQty")){
                             					delete storedDraftValues[idx].promoOrderQty
                             				}else{
                             					delete storedDraftValues.splice(idx,1)
                             				}


                             			}
			                this.showWarningToast('You have entered more '+ x.Category + ' quantity than promotion quantity allowed.')
			                 this.template.querySelector("[data-id='mainDatatable']").draftValues = JSON.parse(JSON.stringify(storedDraftValues.slice()))

             			 }
       			}

  			 })
  			 console.log('#this.selPromotionCopy:'+JSON.stringify(this.selPromotionCopy))
			this.selPromotionCopy = testPromo.slice()

	}
	countPromoQty1(draftValue){
		var allCategoriesArray = []
	     var storedDraftValues = this.template.querySelector("[data-id='mainDatatable']").draftValues
	     console.log('storedDraftValues:'+JSON.stringify(storedDraftValues))
	     var promoCategories = JSON.parse(this.selectedPromotion).map(item => item.Category)
	     console.log('#promoCategories:'+JSON.stringify(promoCategories))

	     var qtyByCategory = [];
	     var total=[]
	     var idx = 1;
		storedDraftValues.forEach(draftValueItem => {
		    console.log('#idx:' + idx)
		    console.log('#0 draftValueItem:'+draftValueItem)
		    let draftValueItemValues = Object.values(draftValueItem);
		    console.log('#0 draftValueItemValues:'+JSON.stringify(draftValueItemValues))
			var masterRow = this.newMasterData.find(masterData => masterData.Id === draftValueItem.Id)
			console.log('#0 masterRow:'+JSON.stringify(masterRow))
			console.log('#0 allCategoriesArray.length :'+allCategoriesArray.length )
			console.log('#0  allCategoriesArray:'+JSON.stringify(allCategoriesArray))
			console.log('allCategoriesArray[0]:'+allCategoriesArray[0])
			if(allCategoriesArray[0] !== undefined && promoCategories.includes(masterRow.Category)){
				var allCategoriesArrayKeys = Object.keys(allCategoriesArray)
				console.log('#1 allCategoriesArrayKeys:'+allCategoriesArrayKeys)
				if(allCategoriesArrayItemKeys.includes(masterRow.Category)){
					console.log('#1 YES ROW CAN BE UPDATED')
				}
//				else{
//					let draftValueItemValues = Object.values(draftValueItem);
//					allCategoriesArray.push({Category: masterRow.Category, promoOrderQty: draftValueItemValues[1]})
//					console.log('#allCategoriesArray:'+JSON.stringify(allCategoriesArray))
//				}
			}else{
					let draftValueItemValues = Object.values(draftValueItem);

					allCategoriesArray.push({Category: masterRow.Category, promoOrderQty: draftValueItemValues[0]})
					console.log('#2 allCategoriesArray:'+JSON.stringify(allCategoriesArray))
  				}
  				idx++;
		})

	      	/*
	    		let draftValueItemKeys = Object.keys(masterRow);
	    		let draftValueItemValues = Object.values(masterRow);
	    		console.log('draftValueItemKeys:'+JSON.stringify(draftValueItemKeys))
	    		if(draftValueItemKeys.includes('promoQtyAmt')){
	    		var masterRow = this.newMasterData.find(masterData => masterData.Id === draftValueItem.Id)
				if(allCategoriesArray.length > 0){
					allCategoriesArray.forEach(a => {
					    var allCategoriesArrayItemKeys = Object.keys(a)
					    if(allCategoriesArrayItemKeys.includes(draftValueItemKeys[0])){
					        allCategoriesArray[draftValueItemKeys[0]] += parseInt(draftValueItemValues[0])
        				 }
    				 })
				}else{
					allCategoriesArray.push({Category:draftValueItemKeys[0],promoOrderQty: draftValueItemValues[1]})
				}
	     	}
	     }
	     console.log('#allCategoriesArray:'+JSON.stringify(allCategoriesArray))
	     */
//			var masterRow = this.newMasterData.find(masterData => masterData.Id === item.Id)
//			console.log('#masterRow:'+JSON.stringify(masterRow))
//			if(allCategoriesArray.find(item => item.Category == masterRow.Category) === undefined){
//			console.log('IF IF IF')
//			    allCategoriesArray.push({Category:masterRow.Category, promoOrderQty : parseInt(draftValue[0].promoOrderQty)})
//				console.log('allCategoriesArray:' + JSON.stringify(allCategoriesArray))
//				total.push(parseInt(draftValue[0].promoOrderQty))
//  			 }
//  			 else{
//
//  			 }
  			 /*
  			 else{
  			     console.log('ELSE allCategoriesArray:' + JSON.stringify(allCategoriesArray))

  			     if(allCategoriesArray.length > 0){
                 			    allCategoriesArray.map(catArray => {
								console.log('#catArray:'+JSON.stringify(catArray))
								var keys = Object.keys(catArray)
								var values = Object.values(catArray)
								console.log('keys[0]' + keys[0])
								console.log('values' + values)
								console.log('allCategoriesArray[keys[0]]:' + catArray[keys[1]])
								console.log('#keys:'+ JSON.stringify(keys))
                 				console.log('#values.includes(masterRow.Category):'+values.includes(masterRow.Category))
                 				console.log('#item.Category:'+item.Category +'  masterRow.Category:'+masterRow.Category)
                 				console.log('#item.Category === masterRow.Category1:'+ (catArray.Category === masterRow.Category))
                 				console.log('#item.Category === masterRow.Category2:'+ (catArray.Category == masterRow.Category))
                 				console.log('#item[keys[1]]'+catArray[keys[1]])
                 			      if(values.includes(masterRow.Category) && (item.Category === masterRow.Category)){
                 			          total.push(parseInt(draftValue[0].promoOrderQty))
                 			        // catArray[keys[1]] += parseInt(draftValue[0].promoOrderQty)
                         			}
                       			})
								console.log('#total  1:'+total)
                 				console.log('allCategoriesArray:'+JSON.stringify(allCategoriesArray))
                 			}
     		 }*/


 	}


	handleOrderSave(event){
	    console.log('this.selPromotionCopy:'+ JSON.stringify(this.selPromotionCopy))
	    debugger
	    var isValid = true;
	    if(this.promotionExists){
	        this.selPromotionCopy.forEach(x => {
	        if(x.qtyLeft > 0) {
				isValid = false
	        }
		})
     	}
     	if(!isValid){
     	    this.showErrorToast('You have not selected valid promotion order quantity.')
			 return;
     	 }
//	    if(this.isOrderValid){
//	        this.showErrorToast('You have not selected valid promotion order quantity. ')
//	        return;
//     		}
 		this.masterDraftValues = this.template.querySelector("[data-id='mainDatatable']").draftValues;
  		 console.log('this.masterDraftValues:'+JSON.stringify(this.masterDraftValues))
		var ordProdIds = this.masterDraftValues.map(item => item.Id)
		var ordProdDetail = this.newMasterData.filter(item => ordProdIds.includes(item.Id))
		ordProdDetail.map(item => {
		    let dVal = this.masterDraftValues.find(x => x.Id === item.Id)
		    if(dVal){
		        if("OrderQty" in dVal){
		            item.OrderQty = dVal.OrderQty
		        }
		        if("promoOrderQty" in dVal){
		            item.promoOrderQty = dVal.promoOrderQty
				}
			}
		 })
		const allData = this.template.querySelector("[data-id='mainDatatable']").data;
		var filteredFreeProduct = allData.filter(x => x.promoFreeQty !== "")
		this.freeProducts = filteredFreeProduct.map(item => item)
		this.selectedProducts = ordProdDetail.map(item => item)
		var previewData = ordProdDetail.concat(filteredFreeProduct)
		console.log('#previewData:'+JSON.stringify(previewData))
		this.previewProducts = previewData.slice();
		console.log('#previewProducts:'+JSON.stringify(this.previewProducts))
		this.totalInclVat = parseFloat(this.totalAmount * 1.20).toFixed(2);
		this.totalExclVat = parseFloat(this.totalAmount).toFixed(2);
		if(this.selectedOrderType == 'P'){ this.showPersonalisation = true; }
		else if(this.selectedOrderType == 'R'){ this.showReplacement = true; }
		else if(this.selectedOrderType == 'B'){  }
		else if(this.selectedOrderType == 'Free Order'){ this.showFree = true; }

		 this.orderPreview = true;
		 this.start = false;
	}

    handleConfirmOrder(event) {

    // 	     const inputFields = [...this.template.querySelectorAll('.validate')].reduce((validSoFar,inputField) => {
    //        	        inputField.reportValidate();
    //        	        return validSoFar && inputField.checkValidity();
    //             },true);



     	    var jsonPayload = {};
     	     console.log('#this.selectedProducts:'+JSON.stringify(this.selectedProducts))
			console.log('#this.freeProducts:'+JSON.stringify(this.freeProducts))
     	    var myProd = this.selectedProducts.slice();
     	     console.log('#myProd 1:'+JSON.stringify(myProd))
     	    this.selectedProducts.forEach(item => {if(item.promoFreeQty === "") { delete item.promoFreeQty}})
     	    console.log('--1')
     	    this.selectedProducts.forEach(item => {if(item.OrderQty === "") { delete item.OrderQty}})
     	      console.log('--2')
     	    this.selectedProducts.forEach(item => {if(item.promoOrderQty === "") { delete item.promoOrderQty}})
     	      console.log('--3')
		 	this.freeProducts.forEach(item => {if(item.promoFreeQty === "") { delete item.promoFreeQty}})
		 	  console.log('--4')
//			this.freeProducts.forEach(item => {if(item.OrderQty === "") { delete item.OrderQty}})
			  console.log('--5')
			this.freeProducts.forEach(item => {if(item.promoOrderQty === "") { delete item.promoOrderQty}})
			  console.log('--6')
     	    console.log('#myProd 2:'+JSON.stringify(myProd))
     	    console.log('####this.reference:'+this.reference)
     	    console.log('####this.deliveryDate:'+this.deliveryDate)

     	    jsonPayload.totalInclVat = this.totalInclVat;
     	    jsonPayload.totalExclVat = this.totalExclVat;
     	    jsonPayload.poReference = this.selectedReference;
     	    jsonPayload.estimatedDeliveryDate = this.selectedDate;
     	    jsonPayload.products = this.selectedProducts.slice();
     	    jsonPayload.freeProducts = this.freeProducts.slice();
     	    jsonPayload.accountId = this.recordId;


    		if(this.showPersonalisation){ jsonPayload.orderType = 'P' }else{ jsonPayload.orderType = this.selectedOrderType}
    		if(this.selectedLaserText){
    		    jsonPayload.laserText = this.selectedLaserText;
      		}

//			alert(1)
//    		console.log('#jsonPayload:' + JSON.stringify(jsonPayload))
//    		console.log('------------->>>')
//    		this.removeEmptyElements(JSON.stringify(jsonPayload))
//    		  console.log('#jsonPayload: Updated:' + JSON.stringify(jsonPayload))
//    		  console.log('<<<-------------')
    // 	    this.selectedProducts.forEach(x => {
    // 	        jsonPayload.products.push(x);
    //      })


          createOrder({'jsonInput' : JSON.stringify(jsonPayload)}).then(result => {
              this.start = true;
              this.orderPreview = false;
    		  this.showPersonalisation = false;
    		  this.showReplacement = false;
    		  this.showFree = false;
              this.selectedProducts = [];
              this.totalAmount = 0.0
              this.navigateToViewAccountPage(result);
          }).catch(error => {
              this.showErrorToast(error.body.message);
          })
     	}

	removeEmptyElements(obj) {
		console.log('removeEmptyElements:')
	  for (let prop in obj) {
		if (obj[prop] === "") {
		  delete obj[prop];
		} else if (typeof obj[prop] === "object") {
		  removeEmptyElements(obj[prop]);
		}
	  }
	}

	filterMaterials(){
		if( this.selectedFamily !== 'All' && this.searchToken === ''){
			const filteredDataByCategory = this.newMasterData.filter(item =>item.Category === this.selectedFamily);
			this.data = filteredDataByCategory.map(item=> { return{...item}} ); // this will enforce to refresh the data in datatable
		}else if(this.selectedFamily === 'All' && this.searchToken === ''){
			this.data = this.newMasterData.map(item=> { return{...item}} );
		}else if(this.selectedFamily === 'All' && this.searchToken ){
			const filteredDataByCategory = this.newMasterData.filter(item => item.ProductName.toLowerCase().includes(this.searchToken.toLowerCase()) && item.Category === this.selectedFamily)
			this.data = filteredDataByCategory.map(item=> { return{...item}} );
		}
	}

	handleClear(event){
		this.totalAmount = 0.00;
		this.showErrorTab = false;
		this.promotionExists = false;
		this.selectedPromotion = [];
		this.template.querySelector("[data-id='mainDatatable']").draftValues = [];
		this.selPromotionCopy = this.selPromotionCopy.slice();
		this.dispatchEvent(new RefreshEvent(this.masterData));
	}

	printObject(msg,item){
		console.log(msg + ' : ' + JSON.stringify(item));
	}

	setOrderStatus(selectedProducts) {
	  	var storedDraftValues = this.template.querySelector("[data-id='mainDatatable']").draftValues
	  	console.log('setOrderStatus - storedDraftValues' + JSON.stringify(storedDraftValues))
	    if(storedDraftValues.length === 0){
			this.isOrderValid = false;
			this.disableSaveButton = 'disabled'
		 }else{
			this.isOrderValid = true;
			this.disableSaveButton = '';
		}
 	}

	calculateTotalAmount(draftValue, qtySum){
	    var storedDraftValues = this.template.querySelector("[data-id='mainDatatable']").draftValues
	    if(draftValue){
			const masterItemRow = this.newMasterData.find(item => item.Id === draftValue[0].Id)
			  storedDraftValues.forEach( item => {
				 if(item.OrderQty){
					let data = this.newMasterData.find(nmd => item.Id === nmd.Id )
					qtySum.push(data.UnitPrice * item.OrderQty)
				}
				if(item.promoOrderQty){
					 let data = this.newMasterData.find(nmd => item.Id === nmd.Id )
					qtySum.push(data.UnitPrice *  item.promoOrderQty)
				}
			})
		}else{
		    storedDraftValues.forEach(item =>  {
		        if(item.OrderQty){
					let data = this.newMasterData.find(nmd => item.Id === nmd.Id )
					this.qtySum.push(data.UnitPrice * item.OrderQty)
				}
				if(item.promoOrderQty){
					 let data = this.newMasterData.find(nmd => item.Id === nmd.Id )
					qtySum.push(data.UnitPrice *  item.promoOrderQty)
				}
      		})
  		}
		this.totalAmount = parseFloat(qtySum.reduce((a,b) => a+ parseInt(b),0)).toFixed(2)
		if(this.totalAmount > 0){
		    this.disableSaveButton = false
		    this.disableSaveDraftButton = false
		    this.disableViewDraftButton = false
  		}else{
			this.disableSaveButton = true
			this.disableSaveDraftButton = true
			this.disableViewDraftButton = true
    	}
	}
	removeEmptyCellValue(draftValue){
	 var storedDraftValues = JSON.parse(JSON.stringify(this.template.querySelector("[data-id='mainDatatable']").draftValues))
	 var updatedStoredDraftValues = [];
		 if(draftValue[0].FreeQty === ""){
		      var idx =  storedDraftValues.findIndex(x => x.FreeQty === "" )
			 let item =  storedDraftValues.find(x => x.Id === draftValue[0].Id)
			 if(item){
				  var keys = Object.keys(item)
				  if(keys.includes('OrderQty') &&  keys.includes("promoOrderQty") || (keys.includes('OrderQty') || keys.includes("promoOrderQty"))){
					   delete storedDraftValues[idx].FreeQty
					  }else{
						  delete storedDraftValues.splice(idx,1)
					 }
				 }
  		}
		 else if(draftValue[0].OrderQty === ""){
			 var idx =  storedDraftValues.findIndex(x => x.OrderQty === "" )
			 let item =  storedDraftValues.find(x => x.Id === draftValue[0].Id)
			 if(item){
			      var keys = Object.keys(item)
			      if(keys.includes('OrderQty') && keys.includes("promoOrderQty")){
			           delete storedDraftValues[idx].OrderQty
       			  }else{
       			      delete storedDraftValues.splice(idx,1)
           		 }
   			 }
		}
		else if(draftValue[0].promoOrderQty === ""){
		  	var idx =  storedDraftValues.findIndex(x => x.promoOrderQty === "" )
		    let item =  storedDraftValues.find(x => x.Id === draftValue[0].Id)
		    if(item){
				var keys = Object.keys(item)
				if(keys.includes('promoOrderQty') && keys.includes("OrderQty")){
					delete storedDraftValues[idx].promoOrderQty
				}else{
					delete storedDraftValues.splice(idx,1)

			 	}
			}
		}else if(draftValue[0].promoOrderQty && (!this.promotionExists)){
		    var idx =  storedDraftValues.findIndex(x => x.promoOrderQty)
		    let item =  storedDraftValues.find(x => x.Id === draftValue[0].Id)
			if(item){
				var keys = Object.keys(item)
				if(keys.includes('promoOrderQty') && keys.includes("OrderQty")){
					delete storedDraftValues[idx].promoOrderQty
				}else{
					delete storedDraftValues.splice(idx,1)
				}
				this.showWarningToast('You are trying to add promotion quantity without selecting promotion.')
			}

 		}
 		else if(draftValue[0].promoOrderQty && this.promotionExists){
			var idx =  storedDraftValues.findIndex(x => x.promoOrderQty)
				let item =  storedDraftValues.find(x => x.Id === draftValue[0].Id)
				let dataRow = this.newMasterData.find(x => x.Id === draftValue[0].Id)
				let promoCategory = JSON.parse(this.selectedPromotion).map(item => item.Category)
				if(!promoCategory.includes(dataRow.Category)){
					var keys = Object.keys(item)
					if(keys.includes('promoOrderQty') && keys.includes("OrderQty")){
						delete storedDraftValues[idx].promoOrderQty
					}else{
						delete storedDraftValues.splice(idx,1)
					}
					 this.showWarningToast("You have chosen wrong product category for the promotion.")
				}

   		}
		//reassign the draftValues

		 this.template.querySelector("[data-id='mainDatatable']").draftValues = JSON.parse(JSON.stringify(storedDraftValues.slice()))
	}
	addOrUpdateFields(draftValue){
	    if(this.selectedProducts.length !== 0){
	        this.selectedProducts.push(draftValue[0])
    	}else{
    	    let idx = this.selectedProducts.findIndex(item => item.Id === draftValue[0].Id)
			if(idx === -1){
				this.selectedProducts.push(draftValue[0])
			}else{
			    const dataItem = this.selectedProducts.find(item => item.Id === draftValue.Id);
			    if(dataItem && draftValue.OrderQty){
			       this.selectedProducts.map(item => { if(item.Id === draftValue[0].Id) { item.OrderQty = draftValue.OrderQty}})
       			}else if(dataItem && draftValue.promoOrderQty){
       			    this.selectedProducts.map(item => { if(item.Id === draftValue[0].Id) { item.promoOrderQty = draftValue.promoOrderQty}})
          		}
   			}
     	}
 	}

//absolute
	updatePromotionQtyCount(draftValue){
	   var promotions = this.selPromotionCopy.map(item => { return {Category:item.Category, OrderQuantity : item.OrderQuantity}})
	   var userOrder = this.template.querySelector("[data-id='mainDatatable']").draftValues
	   var ids = userOrder.map(item => item.Id)
	   var rows = this.newMasterData.filter(item =>  ids.includes(item.Id))
	   var userDataRows = rows.map(item => { return {Category : item.Category, Id: item.Id}})

	   promotions.map(item => {
	        let detailItem = rows.find( x => x.Category === item.Category)
	        if(detailItem){
				  let dRows =  userOrder.filter(a => detailItem.Id)
				if(dRows){
					if(item.Category === detailItem.Category ){
						if(promotions.find(p => p.Category == item.Category).OrderQuantity - dRows.reduce((a,b) => a + parseInt(b.promoOrderQty),0) > 0){
						item.qtyLeft = promotions.find(p => p.Category == item.Category).OrderQuantity - dRows.reduce((a,b) => a + parseInt(b.promoOrderQty),0);
						this.selPromotionCopy = promotions;
						}
					}
				}
         	}
   	   })
    }

	handleSaveDraft(event){
	const mainDataTableSelectedData =	this.template.querySelector("[data-id='mainDatatable']").draftValues;
		if(!mainDataTableSelectedData){
			this.showWarningToast('Please make sure at-least one order exits to save as Draft');
		}else{
			this.isShowDraftModelName = true;
		}
		if(this.isShowModal){
			this.handleViewDraft();
		}
	}

	async handleViewDraft(){
		this.isShowViewDraftModal = true;
		console.log('#this.draftValues:'+this.draftValues)
		await getDraftViewForCustomer({customerId:this.recordId,draftName:this.draftName }).then(result =>{
			if(result){
			this.viewDraftScreenData = result;
			}}).catch(error => {
				alert('Error1:'+JSON.stringify(error))
		});
    }

    handleDraftItemSelectSubmit(event){
        if( this.draftFieldValues.length ===  0  || this.draftFieldValues.length > 1){
            this.showWarningToast('Please select at-least One and Only one draft.')
            return;
        }

        let draftValues = this.template.querySelector("[data-id='draftTable']").data;
        let selectedRowData = draftValues.find(x => x.Description === this.selectedDraftRowDescription)
		getMaterialsForAccount({accountId:'$recordId',searchToken:'$searchToken',draftName: this.selectedDraftRowDescription}).then(result => {
		    for (let i = 0; i < result.length; i++) {
              const resultObj = result[i];
              const index = this.data.findIndex(obj => obj.Id === resultObj.Id);
              if (index !== -1) {
               this.data[index].OrderQty = resultObj.OrderQty;
              }
            }
              refreshApex(this.data)
   		})
        this.isShowViewDraftModal = false;
    }

    handleSaveAsDraft(event){
		this.isShowViewDraftModal = false;
		 var draftValues = this.template.querySelector("[data-id='mainDatatable']").draftValues;
		 this.draftFieldValues = draftValues;
		 this.isShowDraftModelName = false;
		let draftDesc = event.detail.value;

		createDaft({jsonInput:JSON.stringify(this.draftFieldValues),accountId:this.recordId, draftDesc: this.draftName,totalAmount: this.totalAmount }).then(result =>{
		if(result){
				this.showSuccessToast();
				this.draftName = null;
			}else if(error){
				this.showErrorToast(error);
			}
		})
        this.isShowDraftModelName = false;
    }

    handleViewDraftRowSelected(event){
	 this.draftFieldValues = event.detail.selectedRows;

	  this.selectedDraftRowDescription = this.draftFieldValues[0].Description;
    }

	showSuccessToast() {
		const event = new ShowToastEvent({
			title: 'Success!',
			message: 'Records Saved successfully',
			variant: 'success',
			mode: 'dismissable'
		});
		this.dispatchEvent(event);
	}

	showSuccessToast(msg) {
    		const event = new ShowToastEvent({
    			title: 'Success!',
    			message: msg,
    			variant: 'success',
    			mode: 'dismissable'
    		});
    		this.dispatchEvent(event);
    	}

	showErrorToast(ex) {
		const evt = new ShowToastEvent({
			title: 'Error',
			message: ex,
			variant: 'error',
			mode: 'dismissable'
		});
		this.dispatchEvent(evt);
	}

	showWarningToast(msg) {
    		const evt = new ShowToastEvent({
    			title: 'warning',
    			message: msg,
    			variant: 'warning',
    			mode: 'dismissable'
    		});
    		this.dispatchEvent(evt);
    	}

	showPromotionModel() {
		this.masterDraftValues = this.template.querySelector("[data-id='mainDatatable']").draftValues;
	    this.canShowOrderConsole = false;
	    this.canShowPromotion = true;
	}

	hidePromotionModel() {
		this.isShowModal = false;
		if(this.isShowViewDraftModal == true){
		    	this.isShowViewDraftModal = false
  		}
  		if(this.isShowDraftModelName == true){
  		    this.isShowDraftModelName = false;
    	}
	}

	handlePromotionSubmit(){
		this.hidePromotionModel();
	}

	handleNameChange(event){
		this.name = event.detail.value;
	}

	handleDraftName(event){
	    this.draftName = event.detail.value;
 	}

 	selectedRowHandler(event){
     	this.isShowViewDraftModal = false;
 	}

	handleReferenceChange(event) {
	    this.reference = event.detail.value;
		this.selectedReference = event.detail.value;
	}

	handleDateChange(event) {
		this.selectedDate = event.detail.value;
		this.deliveryDate = event.detail.value
	}

	handleLaserTextChange(event) {
		this.selectedLaserText = event.detail.value;
	}


	isInputValid(){
	    let isValid = true;
	    const inputFields = [...this.template.querySelectorAll('.validate')].reduce((validSoFar,inputField) => {
	        inputField.reportValidate();
	        return validSoFar && inputField.checkValidity();
     },true);
 }



 	handleCancelOrder(event) {
		this.orderPreview = false;
		this.start = true;
		this.showPersonalisation = false;
		this.showReplacement = false;
		this.showFree = false;
		console.log('on cancel this.masterDraftValues' +JSON.stringify(this.masterDraftValues))
		this.template.querySelector("[data-id='mainDatatable']").draftValues = this.masterDraftValues;
 	}

 	navigateToViewAccountPage(recordId) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
			recordId: recordId,
			objectApiName: 'ghdOrder__c',
			actionName: 'view'
			},
			});
		}


 	}
