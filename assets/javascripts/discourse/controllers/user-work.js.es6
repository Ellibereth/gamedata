import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Controller.extend({  
  actions: {
    save() {
      const data = {
        billable_hours_week: this.get('model.billable_hours_week'),
        billable_total_month: this.get('model.billable_total_month')
      }
      
      this.set('saving', true);
      
      ajax('/work/update', {
        type: 'PUT',
        data
      }).then(result => {
        if (result.billable_hours_week) {
          this.set('model.custom_fields.billable_hours_week', result.billable_hours_week)
        }
        
        if (result.billable_total_month) {
          this.set('model.custom_fields.billable_total_month', result.billable_total_month)
        }
      }).catch(popupAjaxError).finally(() => {
        this.set('saving', false);
      });
    }
  }
})