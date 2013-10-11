function [ ap ] = evalAP( scores, gt_labels )
%EVALAP Average Precision using Score Matrix
%   Using a score matrix and the ground truth labels computes the average
%   precision used in the Pascal VOC 

confidence = scores';
labels = gt_labels;

assert(size(confidence, 1)==length(labels));

remove_idx = labels<0;
confidence(remove_idx, :)=[];
labels(remove_idx) = [];

unique_cls = unique(labels);
ap = zeros(length(unique_cls), 1);

for i=1:length(unique_cls)
        cls_idx = (labels==unique_cls(i));
        gt = zeros(length(labels), 1);
        gt(cls_idx) = 1;
        gt(~cls_idx) = -1;

        [~,si]=sort(-confidence(:, i));
        tp=gt(si)>0;
        fp=gt(si)<0;

        fp=cumsum(fp);
        tp=cumsum(tp);
        rec=tp/sum(gt>0);
        prec=tp./(fp+tp);

        ap(i)=VOCap(rec,prec);
end

end

% from pascal voc
function ap = VOCap(rec,prec)

mrec=[0 ; rec ; 1];
mpre=[0 ; prec ; 0];
for i=numel(mpre)-1:-1:1
    mpre(i)=max(mpre(i),mpre(i+1));
end
i=find(mrec(2:end)~=mrec(1:end-1))+1;
ap=sum((mrec(i)-mrec(i-1)).*mpre(i));

end