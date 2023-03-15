## Econometric Specification Codebook 


This codebooks's purpose is to create a timeseries dataset of the primary regression specification used within this Economics dissertation.
All of the data files and notebooks can be found at this dissertation's GitHub page: \url{https://github.com/SLBlundell/Economics-Dissertation/}.

The following code creates the methods necessary to construct the regression specification. Namely, it calculates the regression specification's variables. These variables are placed within a time series dataset, with each row representing the specification for a given value of $t$.


```python
import pandas as pd
import numpy as np

class DataProcessor:
    """
    Represents the processing of given data into the primary regression specification
    """

    def __init__(self, returns_file, stringency_file):
        self.df = returns_file
        self.df_stringency = stringency_file
        self.df_spec = pd.DataFrame(columns=['date', 'R_m', 'CSAD', 'CSSD', 'stringency',
                      'lockdown', 'vaccine'])
        """
        Parameters
        ----------
        returns_file : DataFrame
            DataFrame containing market data for selected equities recieved from the
            TuShare API
        stringency_file : DataFrame
            DataFrame containing dates and corresponding stringency index for China
        """

    def sort_data(self):
        """Sorts data based on equity code, then ascending date"""
        self.df = self.df.sort_values(by=['ts_code', 'trade_date']).reset_index(drop=True)

    def calculate_log_returns(self):
        """Calculates daily logarithmic returns for all dates"""
        pd.to_numeric(self.df['close'])
        self.df['daily_log_return'] = 100 * (np.log(self.df['close'].astype('float')) 
                                  - np.log(self.df['close'].astype('float').shift(1)))
        self.df.loc[self.df['trade_date'] == 20200102, 'daily_log_return'] = np.nan

    def calculate_return_market(self, date):
        """Calculates the market return, being the equally-weighted arithmetic mean of
        individual equity log-returns on a given date"""
        return np.mean(self.get_returns_on_date(date))

    def calculate_CSAD(self, date, R_m):
        """Calculates CSAD on a given date"""
        returns_on_date = self.get_returns_on_date(date)
        return (1/self.df['ts_code'].nunique())
        * np.sum(np.abs([x - R_m for x in returns_on_date]))

    def calculate_CSSD(self, date, R_m):
        """Calculates CSSD on a given date"""
        returns_on_date = self.get_returns_on_date(date)
        return (1/(self.df['ts_code'].nunique() - 1))
        * np.sum([(x - R_m) ** 2 for x in returns_on_date]) ** (1/2)

    def get_returns_on_date(self, date):
        """Returns list of all logarithmic equity returns on a given date"""
        return self.df.loc[self.df['trade_date'] == date, 'daily_log_return'].tolist()

    def process_data(self):
        """Iterates through all unique dates within datasets, creating a row of all
        variables within the regression specification, and appending the main
        specification dataset with said rows"""
        self.calculate_log_returns()
        
        for date in self.df.trade_date.unique().tolist():
            R_m = self.calculate_return_market(date)
            CSAD = self.calculate_CSAD(date, R_m)
            CSSD = self.calculate_CSSD(date, R_m)
            stringency = self.df_stringency.loc[self.df_stringency['Date'] == int(date),
                        'StringencyIndex_WeightedAverage'].item()
            lockdown = self.df_stringency.loc[self.df_stringency['Date'] == int(date),
                        'C6E_Stay at home requirements'].item()
            vaccine = self.df_stringency.loc[self.df_stringency['Date'] == int(date),
                        'PopulationVaccinated'].item()
            new_row = pd.DataFrame({'date' : date, 
                                 'R_m' : R_m, 
                                 'CSAD' : CSAD,
                                 'CSSD' : CSSD,
                                 'stringency' : stringency,
                                 'lockdown' : lockdown,
                                 'vaccine': vaccine}, 
                                index=[0])
            self.df_spec = pd.concat([self.df_spec, new_row], ignore_index=True)

    def save_data(self, output_file):
        """Saves the dataset of timeseries data to a comma-deliminated file (csv)"""
        self.df_spec.to_csv(output_file)

```

Here we gather our Chinese equity market data, utilizing the China-based community run API TuShare \url{https://tushare.pro/}. 

The `daily_log_return` column of the resultant dataset represents logarithmic returns within our variables, with $t$ being the `trade_date` and $i$ the `ts_code`.

**BE WARNED**: 
Due to the community nature of the TuShare API, only 6000 values can be requested at once for most users. As such, the method below splits the data requests into 20-day batches, which results in a considerably long runtime for the whole 3-year period.

**Note**: `config.api_key` must be replaced with your own API key, which can be obtained from TuShare by signing up to the platform using the link provided above.


```python
import tushare as ts
import re
import config

class GetChineseEquityData:
    """Represents code necessary to retrieve data from TuShare API"""

    def __init__(self, list_path, start_date, end_date):
        """
        Parameters
        ----------
        list_path : Literal
            The list of equities you are retrieving data for. Data should be csv file, 
            containing the column name "code" with all your equity codes and "exchange"
            containing the equity's exchange.
        start_date : int
            The start date of the period you want to retrieve data for
        end_date : int
            The end date of the period you want to retrieve data for
        """
        
        self.list_path = list_path
        self.start_date = start_date
        self.end_date = end_date
        self.df_codes = pd.read_csv(list_path)
        ts.set_token(config.api_key)
        self.pro = ts.pro_api()

    def get_codes(self):
        """Returns a string of codes separated by commas."""
        return ','.join([
            f"{row['code'][0:6]}.SH" if row['exchange'] == 'Shanghai' 
            else f"{row['code'][0:6]}.SZ" 
            for _, row in self.df_codes.iterrows()
        ])

    def get_returns_data(self):
        """Retrieves market data for all equities in the list within the specified date range
        using batch queries."""
        codes = self.get_codes()
        t = self.start_date
        appended_data = []
        
        while t < self.end_date:
            data = self.pro.daily(ts_code=codes, start_date=str(t), end_date=str(t + 20))
            appended_data.append(data)
            t += 21
        
        appended_data = pd.concat(appended_data)
        return appended_data
```

Defining the list of equities and timeframe:


```python
csi_list_path = r'data/csi_constituents.csv'
data_components = GetChineseEquityData(csi_list_path, 20200101, 20230101)
returns_data = data_components.get_returns_data()
```

Getting the COVID-19 Government Response data from the Oxford COVID Policy Tracker's GitHub \url{https://github.com/OxCGRT/covid-policy-tracker}:


```python
import requests
import io
import pandas as pd
import numpy as np

class GetStringencyData:

    def __init__(self, years):
        """
        Parameters
        ----------
        years : List
            List of years you want data retrieved for, in string format
        """

        self.url_base = "https://raw.githubusercontent.com/OxCGRT/covid-policy-tracker" +
        "/master/data/OxCGRT_nat_differentiated_withnotes_{}.csv"
        self.years = years
        self.stringency_data = pd.DataFrame(columns=['Date',
                              'StringencyIndex_WeightedAverage'])

    def get_data(self, year):
        """requests HTML content from the OxCGRT GitHub, returns content in a DataFrame"""
        url = self.url_base.format(year)
        data = requests.get(url).content
        df = pd.read_csv(io.StringIO(data.decode('utf-8')))
        return df

    def filter_data(self, df):
        """Filters data so that only dates relevant variables for China is included"""
        df = df.loc[df['CountryName'] == 'China']
        df = df[['Date', 'StringencyIndex_WeightedAverage', 'C6E_Stay at home requirements',
            'PopulationVaccinated']].replace(np.nan, 0)
        return df

    def concatenate_data(self, df):
        """Combines data for each year specified into one DataFrame"""
        self.stringency_data = pd.concat([self.stringency_data, df]).reset_index(drop=True)

    def get_and_filter(self):
        """Iterates over each year specified, retrieving and filtering data from OxCGRT"""
        for year in self.years:
            df = self.get_data(year)
            df = self.filter_data(df)
            self.concatenate_data(df)
        
        return self.stringency_data
```


```python
sd = GetStringencyData(["2020", "2021", "2022", "2023"])
stringency_data = sd.get_and_filter()
```


```python
returns_data = pd.read_csv('data/returns_2020_2023.csv')
```

Finally, we can run our data processor, which returns a dataset of rows representing our primary specification at each value of $t$.


```python
data_processor = DataProcessor(returns_data, stringency_data)
data_processor.sort_data()
data_processor.process_data()
data_processor.save_data('data/spec_1_stringency_CSSD_CSAD_expanded.csv')
```
