/**
 * Created by Jayakumar Mogenahall on 18/02/2023.
 */

import { LightningElement,track } from 'lwc';

export default class OrderConsole extends LightningElement {
name;
	 @track isShowModal = false;
	   showPromotion() {
             this.isShowModal = true;
         }

         hideModalBox() {
             this.isShowModal = false;
         }

         handleSubmit(){
             alert(this.name);
         }

         handleNameChange(event){

             this.name = event.detail.value;
         }

 }