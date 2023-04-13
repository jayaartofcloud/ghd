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


const columns = [
    { label: 'Product Name', fieldName: 'ProductName', editable: false },
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', editable: false, hideDefaultActions:"true", typeAttributes:{currencyCode: 'GBP',variant:"Error"}, cellAttributes:{iconName:{fieldName:'iconName'}, iconClass:"slds-current-color",iconPosition:'right'}},
    { label: 'Order Qty', fieldName: 'OrderQty', type: 'number', editable: true, hideDefaultActions:"true" },
];

const draftColumns = [
	{ label: 'Draft Name', fieldName: 'DraftRecordName', editable: false,hideDefaultActions:"true"  },
	{label: 'Description', fieldName:'Description', editable: false,hideDefaultActions:"true"  },
	{ label: 'Total Value', fieldName: 'TotalAmount', type: 'currency', editable: false,hideDefaultActions:"true",  typeAttributes:{currencyCode: 'GBP'}},
	{label: 'Last Modified By', fieldName: 'LastModifiedBy', hideDefaultActions:"true", editable:false},
	{label: 'Last Modified Date', fieldName: 'LastModifiedDate',hideDefaultActions:"true",  editable:false}

];

export default class orderEditor extends LightningElement {
	@api recordId;
	@track isShowModal = false;
	@track productNav = null;
	draftValues =[];
	data = [];
	masterData = [];
	columns = columns;
	draftColumns = draftColumns;
	rowOffset = 0;
	selectedFamily = '--Select Family--';
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
	totalInclVat = 0.00;
	totalExclVat = 0.00;
	selectedDate = '';
	selectedReference = '';


	get options() {
        return [
            {label:'All',value:'All'},
            {label: 'Styler', value:'Styler'},
            {label: 'ANZ - Prior Q Dryer', value:'ANZ - Prior Q Dryer'},
            {label: '12 Core Curl', value:'12 Core Curl'},
        ];
    }

	get optionsType() {
        return [
            {label:'Standard Order',value:'Standard Order'},
            {label: 'Replacement Order', value:'Replacement Order'},
            {label: 'Personalisation Order', value:'Personalisation Order'},
            {label: 'Free Order', value:'Free Order'},
        ];
    }

	@wire(getMaterialsForAccount, {accountId:'$recordId',searchToken:'$searchToken',draftName:null})
	wiredResult({error,data}){

	this.wiredDataResult = data;
		if(data){
		    this.dataSpinner = false;
		    this.data = data;
		 	this.data = data.map(item=> { return{...item, OrderQty: "" }} );
		  	console.log('#this.data:'+ JSON.stringify(this.data))
//			this.data = data.map(item=>{
//				let iconName = item.AvailableStock <= 5  ? "utility:down" : item.AvailableStock > 5 &&  item.AvailableStock <= 15 ? "utility:left": "utility:up";
//				let redColor ="redColor";
//				return {...item, "iconName": iconName,"iconColor":redColor}
//
//			});

			}
		else if(error){
		     	this.dataSpinner = false;
				alert(JSON.stringify(error));
		}


	this.data.forEach(function(product){
		    product.OrderQty ='';
  	});
  			this.masterData = this.data;
	}
	connectedCallback() {
	    const  icons =   this.template.querySelectorAll('lightning-icon[data-key="left"]')
	    loadStyle(this, dataTableStyles);
		//this.data = generateData({ amountOfRecords: 100 });
	}

	handleProductFamilyChange(event){
		this.selectedFamily = event.detail.value;
		this.makeProductDumpCall();
	}

	handleOrderTypeChange(event){
		this.selectedOrderType = event.detail.value;
	}

	handleSearch(event){
		this.searchToken = event.target.value;
		this.makeProductDumpCall();
	}

	validateDataTable(event){
	    this.errors
 }

handleOrderSave(event){
//    if(!validateDataTable(event))
//    return;

	 var updatedValues = this.template.querySelector("lightning-datatable");
	 var rows = updatedValues.data;
	 console.log('datatable selected values:' + JSON.stringify(rows))
	 this.draftFieldValues = rows;
		var newRow;
		this.selectedRowData = this.data.map(row => {
			if (row.OrderQty != null && row.OrderQty !=0) {
				this.selectedProducts.push(row);
			}
		});
		const message = {
			hide: "true",
		}
		createDaft({jsonInput:JSON.stringify(this.selectedRowData),accountId:this.recordId, draftDesc: this.draftName,totalAmount: this.totalAmount }).then(result =>{
		if(result){
				this.showSuccessToast();
				this.template.querySelector("lightning-datatable").draftValues = [];

			}else if(error){
				this.showErrorToast(error);
			}
  		})
		// Generate total with/without VAT.
		this.totalInclVat = parseFloat(this.totalAmount * 1.20).toFixed(2);
		this.totalExclVat = parseFloat(this.totalAmount).toFixed(2);
		this.start = false;
		this.orderPreview = true;
  		}

		makeProductDumpCall(){
			productsDump({family:this.selectedFamily, searchToken : this.searchToken}).then(result => {
					this.data = result.map(item=>{
					let iconName = item.AvailableStock <= 5  ?  'utility:down' : item.AvailableStock > 5 &&  item.AvailableStock <= 15 ? 'utility:right' : 'utility:up' ;
					 return {...item, "src": iconName }
				});
			}).catch(error => {
				// console.log('Error1:' + JSON.stringify(error));
			})
		}

		handleClear(event){
			this.template.querySelector("lightning-datatable").draftValues = [];
			this.selectedOrders = [];
			this.selectedProducts = [];
			this.draftValues = [];
			this.totalAmount = 0.00;
			this.data = this.masterData.slice();
			console.log('data:'+JSON.stringify(this.data));
			this.dispatchEvent(new RefreshEvent(this.data));
		}

		printObject(msg,item){
			console.log(msg + ' : ' + JSON.stringify(item));
		}

		handleOnCellChange(event){
			var sum = []
			this.selectedProducts.push(event.detail.draftValues);
			let newItem = event.detail.draftValues[0]
			this.selectedProducts = this.selectedProducts.flat().map(({OrderQty,Id}) => ({OrderQty,Id}));
			let oldItemIdx = this.selectedProducts.findIndex(x => x.Id == newItem.Id && x.OrderQty !== newItem.OrderQty )
			let oldItem = this.selectedProducts.find(x => x.Id == newItem.Id && x.OrderQty !== newItem.OrderQty )
			if(oldItemIdx !== -1){
				this.selectedProducts.splice(oldItemIdx,1)
			}
			  this.selectedProducts.forEach(x => {
				  let dataItem = this.data.find(a => a.Id == x.Id)
				  x.UnitPrice = dataItem.UnitPrice
				  x.ProductName = dataItem.ProductName
				  x.materialNumber = dataItem.MaterialCode
				  x.quantity = x.OrderQty
				  sum.push(x.OrderQty * dataItem.UnitPrice)
			  })

		  this.totalAmount =  parseFloat(sum.reduce((a,b) =>a + b,0)).toFixed(2)

		}

		handleSaveDraft(event){
			this.draftValues = this.template.querySelector('lightning-datatable').draftValues;
			console.log('this.draftValues handleSaveDraft :'+ JSON.stringify(this.draftValues) )
			if(this.draftValues.length == 0){
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
		 console.log('this.recordId 1:' + this.recordId + ' this.draftName 1:'+this.draftName)
		  await getDraftViewForCustomer({customerId:this.recordId,draftName:this.draftName }).then(result =>{
				  if(result){
				   	this.viewDraftScreenData = result;
				 }}).catch(error => {
				      alert('Error:'+JSON.stringify(error))
     });
    }

    handleDraftItemSelectSubmit(event){
        if( this.draftFieldValues.length ===  0  || this.draftFieldValues.length > 1){
            this.showWarningToast('Please select at-least One and Only one draft.')
            return;
        }

        let draftValues = this.template.querySelector("[data-id='draftTable']").data;
        console.log('###this.selectedDraftRowDescription:'+ this.selectedDraftRowDescription)
        let selectedRowData = draftValues.find(x => x.Description === this.selectedDraftRowDescription)
		getMaterialsForAccount({accountId: this.recordId,searchToken:'$searchToken',draftName: this.draftName}).then(result => {
		    for (let i = 0; i < result.length; i++) {
              const resultObj = result[i];
              const index = this.data.findIndex(obj => obj.Id === resultObj.Id);
              if (index !== -1) {
                  console.log('## resultObj.OrderQty:'+ resultObj.OrderQty)
               this.data[index].OrderQty = resultObj.OrderQty;
              }
            }
              refreshApex(this.data)
             console.log('#this.Data1:' + JSON.stringify(this.data))
   		})


        this.isShowViewDraftModal = false;

    }


    handleSaveAsDraft(event){
		this.isShowViewDraftModal = false;

		 var draftValues = this.draftValues;
		 console.log('draftValues:' + JSON.stringify(draftValues))
		 this.draftFieldValues = draftValues;
		 this.isShowDraftModelName = false;


		let draftDesc = event.detail.value;



//		var newRow;
//		this.selectedRowData = this.data.map(row => {
//			const changes = draftValues.find(changedElement => changedElement.Id  === row.Id);
//
//			if(changes !== undefined || changes !== null){
//			  newRow = Object.assign({}, row);
//			}
//			if(changes)
//			{
//				return Object.assign(newRow, changes)
//			}
//		});

		createDaft({jsonInput:JSON.stringify(this.draftFieldValues),accountId:this.recordId, draftDesc: this.draftName,totalAmount: this.totalAmount }).then(result =>{
		if(result){
				this.showSuccessToast();
				this.draftName = null;
			}else if(error){
				// console.log('error:'+error);
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

	showErrorToast(ex) {
		const evt = new ShowToastEvent({
			title: 'Error',
			message: ex,
			variant: 'error',
			mode: 'dismissable'
		});
		this.dispatchEvent(evt);
	}
	showWarningToast(ex) {
    		const evt = new ShowToastEvent({
    			title: 'warning',
    			message: ex,
    			variant: 'warning',
    			mode: 'dismissable'
    		});
    		this.dispatchEvent(evt);
    	}

// Promotion related functions
	showPromotionModel() {
		this.isShowModal = true;
	}

	hidePromotionModel() {
		this.isShowModal = false;
		if(this.isShowViewDraftModal == true){
		    	this.isShowViewDraftModal = false
  		}
  		if(this.isShowDraftModelName == true){
  		    this.isShowDraftModelName = false;
    	}
    	this.totalAmount = null
	}
	handlePromotionSubmit(){
//		alert('Name is '+this.name);
		this.hidePromotionModel();
	}

	handleNameChange(event){
		this.name = event.detail.value;
	}

	handleDraftName(event){
	    alert(event.detail.value)
	    this.draftName = event.detail.value;
 	}

 	selectedRowHandler(event){
     	this.isShowViewDraftModal = false;
 	}

	handleReferenceChange(event) {
		this.selectedReference = event.detail.value;
	}

	handleDateChange(event) {
		this.selectedDate = event.detail.value;
	}

 	handleConfirmOrder(event) {

 	    var jsonPayload = {};
 	    jsonPayload.totalInclVat = this.totalInclVat;
 	    jsonPayload.totalExclVat = this.totalExclVat;
 	    jsonPayload.poReference = this.selectedReference;
 	    jsonPayload.estimatedDeliveryDate = this.selectedDate;
 	    jsonPayload.products = [];
 	    jsonPayload.accountId = this.recordId;
 	    this.selectedProducts.forEach(x => {
 	        jsonPayload.products.push(x);
      })

      createOrder({'jsonInput' : JSON.stringify(jsonPayload)}).then(result => {
          this.showSuccessToast();
          this.start = true;
          this.orderPreview = false;
          this.selectedProducts = [];
          this.totalAmount = 0.0
          console.log('result:'+result)

      }).catch(error => {
          this.showErrorToast(error.body.message);
      })
 	}

 	handleCancelOrder(event) {
		this.orderPreview = false;
		this.start = true;
		this.totalAmount = 0;
 	}

}