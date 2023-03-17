function n = normr(m)

[mr,mc]=size(m);
if (mc == 1)
  n = m ./ abs(m);
else
  n=sqrt(ones./(sum((m.*m)')))'*ones(1,mc).*m;
end