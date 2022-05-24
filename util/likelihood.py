from itertools import product
import time
import pandas as pd
import numpy as np



#it takes multiple sequences as input
seq = input() #taking input sequence + think about N in the sequence 
seq = seq.upper()

#generating 64 codons for dict
nucl = ['A','U','G','C'] #RNA nucleotides
cod = [''.join(new_nucl) for new_nucl in product(nucl, repeat = 3)]				
#print(cod)
#print(len(cod))  to check whether everything is alright, should be 64



#generating the dict for frequencies
frequency=dict()
for i in range(len(seq)-2):  #-2 or the codons will be shorter than 3
	new_cod = seq[i:i+3]
	#print(new_cod)
	frequency[new_cod]=frequency.get(new_cod,0)+1
#print(frequency)



df = pd.DataFrame(frequency.items(), columns = ['codon','frequency'])
df.frequency = (df.frequency)/(len(df.frequency))


df['log'] = np.log10(df.frequency)
likelihood = df['log'].sum()
print('likelihood =', likelihood)



print(df)
mean = df['frequency'].mean()
sd = df['frequency'].std()
print('mean = ',mean)
print('stddev = ',sd)



#3 sigma interval:
print('3 sigma: [',(mean-3*sd),';',(mean+3*sd),']') 
print('codons not in 3 sigma:')
print(df[(df.frequency<(mean-3*sd)) | (df.frequency>(mean+3*sd))])



#plt.plot(df.frequency, norm.pdf(df['frequency'],mean,sd))
#ax = fig.add_axes([0,0,1,1])
#ax.bar(df.codon,df.frequency)
#ax.set_xticks(df.codon)
#plt.show()
#plt.savefig('result.pdf')



print('time of run:', time.process_time())
