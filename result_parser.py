import re
from subprocess import check_output
import csv

files_list = check_output(['ls', 'results']).decode('utf-8').split('\n')
envs = ['kubernetes', 'swarm', 'native']
params = [
    'connections',
    'requests',
    'replies',
    'test_duration_s',
    'reply_time_ms',
    'conn_time_min_ms',
    'conn_time_avg_ms',
    'conn_time_max_ms',
    'conn_time_median_ms',
    'conn_time_stddev_ms',
    'reply_status_200_count',
    'reply_status_500_count',
    'errors_total'
]


class ResultParser:
    def __init__(self, files):
        self.results_dict = {
            'kubernetes': {},
            'swarm': {},
            'native': {},
        }
        self.stats_service_files = filter(lambda x: 'stats_svc' in x, files)
        self.order_service_files = filter(lambda x: 'order_svc' in x, files)
        self.order_db_files = filter(lambda x: 'order_db' in x, files)

    @staticmethod
    def get_env_type(filename):
        if filename.startswith('k'):
            return 'kubernetes'
        if filename.startswith('s'):
            return 'swarm'
        if filename.startswith('n'):
            return 'native'

    @staticmethod
    def filter_connections(line):
        return 'Total: connections' in line

    @staticmethod
    def map_connections(line):
        res = re.search(r'connections ([0-9]{0,9})', line)
        return res.group(1)

    @staticmethod
    def map_requests(line):
        res = re.search(r'requests ([0-9]{0,9})', line)
        return res.group(1)

    @staticmethod
    def map_replies(line):
        res = re.search(r'replies ([0-9]{0,9})', line)
        return res.group(1)

    @staticmethod
    def filter_reply_time(line):
        return 'Reply time [ms]:' in line

    @staticmethod
    def map_reply_times(line):
        res = re.search(r'response ([0-9]{0,9}\.[0-9])', line)
        return res.group(1)

    @staticmethod
    def map_test_duration(line):
        res = re.search(r'test-duration ([0-9]{0,9}\.[0-9]{0,3})', line)
        return res.group(1)

    @staticmethod
    def map_connection_time(val):
        def map_conn_time(line):
            res = re.search(r'{}'.format(val) + r' ([0-9]{0,9}\.[0-9])', line)
            return res.group(1)

        return map_conn_time

    @staticmethod
    def map_200_status(line):
        res = re.search(r'2xx=([0-9]{0,9})', line)
        return res.group(1)

    @staticmethod
    def map_500_status(line):
        res = re.search(r'5xx=([0-9]{0,9})', line)
        return res.group(1)

    @staticmethod
    def map_errors_total(line):
        res = re.search(r'total ([0-9]{0,9})', line)
        return res.group(1)

    def start_stats_service(self):
        self.parse_httperf_for(self.stats_service_files)
        return self.results_dict

    def start_order_service(self):
        self.parse_httperf_for(self.order_service_files)
        return self.results_dict

    def parse_httperf_for(self, service):
        for result_file in service:
            with open(f'results/{result_file}', 'r') as result:
                env_type = self.get_env_type(result_file)
                lines = result.readlines()

                connection_lines = list(filter(lambda x: 'Total: connections' in x, lines))
                connections_values = list(map(self.map_connections, connection_lines))
                requests_values = list(map(self.map_requests, connection_lines))
                replies_values = list(map(self.map_replies, connection_lines))
                test_duration_values = list(map(self.map_test_duration, connection_lines))

                reply_time_lines = list(filter(lambda x: 'Reply time [ms]:' in x, lines))
                reply_time_values = list(map(self.map_reply_times, reply_time_lines))

                reply_status_lines = list(filter(lambda x: 'Reply status:' in x, lines))
                reply_status_200_count = list(map(self.map_200_status, reply_status_lines))
                reply_status_500_count = list(map(self.map_500_status, reply_status_lines))

                errors_total_lines = list(filter(lambda x: 'Errors: total' in x, lines))
                errors_total_values = list(map(self.map_errors_total, errors_total_lines))

                conn_time_lines = list(filter(lambda x: 'Connection time [ms]: min' in x, lines))
                for val in ['min', 'avg', 'max', 'median', 'stddev']:
                    values = list(map(self.map_connection_time(val), conn_time_lines))
                    self.results_dict[env_type][f'conn_time_{val}_ms'] = values

                self.results_dict[env_type]['connections'] = connections_values
                self.results_dict[env_type]['requests'] = requests_values
                self.results_dict[env_type]['replies'] = replies_values
                self.results_dict[env_type]['reply_time_ms'] = reply_time_values
                self.results_dict[env_type]['test_duration_s'] = test_duration_values
                self.results_dict[env_type]['reply_status_200_count'] = reply_status_200_count
                self.results_dict[env_type]['reply_status_500_count'] = reply_status_500_count
                self.results_dict[env_type]['errors_total'] = errors_total_values


class CSVParser:
    def __init__(self, results_dict):
        self.results_dict = results_dict

    def genreate_csv_for(self, env, svc):
        size = len(self.results_dict[env][params[0]])
        data_list = [params]

        for i in range(size):
            row = []
            for value in params:
                row.append(rp.results_dict[env][value][i])
            data_list.append(row)

        with open(f'{env}_{svc}.csv', 'w') as file:
            writer = csv.writer(file)
            writer.writerows(data_list)


rp = ResultParser(files_list)

# Stats service
results = rp.start_stats_service()
csvp = CSVParser(results)
for environ in envs:
    csvp.genreate_csv_for(environ, 'stats_service')

# Order service
results = rp.start_order_service()
csvp = CSVParser(results)
for environ in envs:
    csvp.genreate_csv_for(environ, 'order_service')

# print(rp.results_dict['kubernetes']['reply_time_ms'])