one_hit=0.0
levels=36
l=int(input("which level(3^n): "))
score=pow(3,l-1)

for i in range(0,l-1):
    one_hit+=pow(3,i)/pow(2,i+1)
    print(f"{i:>3}_{one_hit:.2f}",end="\t")
one_hit+=pow(3,l-1)/pow(2,l-1)
print(f"{l:>3}_{one_hit:.2f}",end="\t")

print(f"\nto reach {score}, need {score/one_hit:.2f} hits.")