/**
 * Created by Jayakumar Mogenahall on 11/04/2023.
 */

public class PriceListApiAsync implements Finalizer, Queueable{

    public void execute(QueueableContext ctx) {
        System.debug('Executing queueable job:' + ctx.getJobId());
        PriceListAPIProcessQueueable ppq = new PriceListAPIProcessQueueable();
        System.attachFinalizer(ppq);
        System.debug('Completed executing job');
    }

    public void execute(FinalizerContext ctx) {
        Id jobId = ctx.getAsyncApexJobId();
        System.debug('Executing finalizer attached the Job :' + jobId);
        if(ctx.getResult() == ParentJobResult.SUCCESS){
            System.debug('Job completed Successfully');
        }else{
            System.debug('Job completed with Error');
            System.debug('Error message:' + ctx.getException().getMessage());
        }
        System.debug('Completed executing Finalizer');

    }
}