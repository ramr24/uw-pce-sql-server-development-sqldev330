strData = '''
"Products":{
 {"Name":"ProdA","Price":9.99,"Category":"Cat1"}
 {"Name":"ProdB","Price":1.99,"Category":"Cat1"}
 {"Name":"ProdC","Price":1.99,"Category":["Cat1","Cat2"]}
}
'''
fh = open('ProductData.json', 'w')
fh.write(strData)
fh.close()

