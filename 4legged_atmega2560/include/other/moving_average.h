#ifndef MOVING_AVERAGE_H_
#define MOVING_AVERAGE_H_

#include <stdint.h>			// uint8_t, uint16_t

template
<
	typename T1,			// samples type
	typename T2,			// sum type
	uint8_t sample_count
>
class MovingAverageFilter
{
public:
//private:
	uint8_t i;
	T1 samples[sample_count];
	T2 sum;
public:
	MovingAverageFilter() : i(0), sum(0) {}
	
	T1 getResult()
	{
		return sum / sample_count;
	}
	//void addSample(T1 new_val)
	//{
		//sum += new_val - samples[i]; // i points to the oldest value
		//
		//samples[i++] = new_val;
		//if (i >= sample_count)
			//i = 0;
	//}
	bool addSample(T1 new_val)
	{
		samples[0] = new_val;
		return true;
		samples[i++] = new_val;
		if (i >= sample_count)
		{
			i = 0;
			return true; // sample array is filled
		}
		return false; // sample array isn't filled yet
	}
	//T2 Filter(T1 new_val)
	//{
		//addSample(new_val);
		//return getResult();
	//}
	T1 Filter()
	{
		sum = 0;
		for(uint8_t j = 0; j < sample_count; j++)
			sum += samples[j];
		i = 0;
		return getResult();
	}
	
	constexpr uint8_t getSampleCount()
	{
		return sample_count;
	}
};



#endif /* MOVING_AVERAGE_H_ */