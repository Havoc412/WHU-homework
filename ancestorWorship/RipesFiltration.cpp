#include<bits/stdc++.h>
using namespace std;

const int INSTRUCT_LEN = 8;

int main()
{
	cout<<"����˵����ֱ�Ӹ��ƽ������س������롮EOF��������\n";
	string instruct;
	vector<string> vec;
	
	while(getline(cin, instruct)) {
		if(instruct == "EOF")
			break;
			
		bool flag = false;
		int pos = 0;
		for(int i=0; i<instruct.size(); i++) {
			if(instruct[i] == ':') {
				flag = true;
				continue;
			}
			if(flag && instruct[i] != ' ') {
				pos = i;
				break;
			}
		}
		string temp = instruct.substr(pos, INSTRUCT_LEN);
		vec.emplace_back(temp);
	}
	
	for(int i=0; i<vec.size(); i++) {
		if(i % 4 == 0)
			cout<<endl<<vec[i];
		else
			cout<<" "<<vec[i];
	}
//	cout<<";";
	return 0;
}
