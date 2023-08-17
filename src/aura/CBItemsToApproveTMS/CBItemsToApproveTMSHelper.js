({
helpgetItemsToApprove: function (cmp, event) { 
     let action = cmp.get("c.getBudgetsListToApprove");
      action.setCallback(this, function (response) {
               let state = response.getState();
               if (state === "SUCCESS") {
                   let result = response.getReturnValue();
                    result.forEach(function(item, i, arr) {
                        item.SubmittTime__c = (new Date(item.SubmittTime__c)).toLocaleString('en-US');
                    });    
                    cmp.set("v.Budgets", result);
                } else {
                  let errors = response.getError();
                  let message = 'Unknown error'; 
                  if (errors && Array.isArray(errors) && errors.length > 0) message = errors[0].message;
               _cl(message,'red');
               }
           });
           $A.enqueueAction(action);  
},
helpopenLog: function (cmp, event) { 
     let appId = event.target.id;
     window.open('/' + appId,'_blank');    
},
_cl: function (cmp, event){
    try {
        if (typeof message === "object") message = message.toString();
        console.log('%c🌩️ ' + message, 'color:' + color + '; ' +
            'font: 1 Tahoma; ' +
            'font-size: 1.2em; ' +
            'font-weight: bolder; ' +
            'padding: 2px;');
    } catch (e) {

    }
}
})