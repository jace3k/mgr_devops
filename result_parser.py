import os
import re
from subprocess import check_output
import csv

files_list = check_output(['ls', 'results']).decode('utf-8').split('\n')

params = [
    'environment',
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
    'errors_total',
]

params_db = [
    'environment',
    'test_type',
    'table_size',
    'queries_read',
    'queries_write',
    'queries_other',
    'queries_total',
    'transactions',
    'latency_min_values',
    'latency_avg_values',
    'latency_max_values',
    'latency_95_percent_values',
    'latency_sum_values',
]

platforms = [
    'cloud',
    'home',
    'pwr',
]

envs = [
    'kubernetes',
    'swarm',
    'native'
]

test_types = [
    'stats_svc',
    'order_svc',
    'order_db',
]


class ResultParser:
    def __init__(self, files, httperf_headers_list, sysbench_headers_list):
        self.files = files
        self.httperf_headers_list = httperf_headers_list
        self.sysbench_headers_list = sysbench_headers_list

    def generate_csv(self, plat, test_type):
        files = list(filter(lambda x: '{}_{}'.format(plat, test_type) in x, self.files))
        parser = 'httperf' if test_type in ['order_svc', 'stats_svc'] else 'sysbench'
        parser_func = self.httperf_parser if parser == 'httperf' else self.sysbench_parser

        print(files)
        results_dict = self.initialize_results_dict(
            self.httperf_headers_list if parser == 'httperf' else self.sysbench_headers_list
        )
        for filename in files:
            parser_func(filename, results_dict)

        self.write_csv(
            'results_csv/{0}/{0}_{1}.csv'.format(plat, test_type),
            results_dict,
            self.httperf_headers_list if parser == 'httperf' else self.sysbench_headers_list
        )

    @staticmethod
    def initialize_results_dict(headers):
        results_dict = {}
        for header in headers:
            results_dict[header] = []
        return results_dict

    def httperf_parser(self, filename, results_dict):
        with open(f'results/{filename}', 'r') as f:
            env_type = self.get_env_type(filename)
            lines = f.readlines()

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
                results_dict[f'conn_time_{val}_ms'].extend(values)

            results_dict['connections'].extend(connections_values)
            results_dict['requests'].extend(requests_values)
            results_dict['replies'].extend(replies_values)
            results_dict['reply_time_ms'].extend(reply_time_values)
            results_dict['test_duration_s'].extend(test_duration_values)
            results_dict['reply_status_200_count'].extend(reply_status_200_count)
            results_dict['reply_status_500_count'].extend(reply_status_500_count)
            results_dict['errors_total'].extend(errors_total_values)
            results_dict['environment'].extend([env_type] * len(connections_values))

    def sysbench_parser(self, filename, results_dict):
        with open(f'results/{filename}', 'r') as f:
            env_type = self.get_env_type(filename)
            lines = f.readlines()

            queries_read_values = self.queries_performed(lines, 'read')
            queries_write_values = self.queries_performed(lines, 'write')
            queries_other_values = self.queries_performed(lines, 'other')
            queries_total_values = self.queries_performed(lines, 'total')
            transactions_values = self.queries_performed(lines, 'total number of events')

            latency_min_values = self.latency(lines, 'min')
            latency_avg_values = self.latency(lines, 'avg')
            latency_max_values = self.latency(lines, 'max')
            latency_95_percent_values = self.latency(lines, '95th percentile')
            latency_sum_values = self.latency(lines, 'sum')
            print(latency_sum_values)

            results_dict['queries_read'].extend(queries_read_values)
            results_dict['queries_write'].extend(queries_write_values)
            results_dict['queries_other'].extend(queries_other_values)
            results_dict['queries_total'].extend(queries_total_values)
            results_dict['transactions'].extend(transactions_values)

            results_dict['latency_min_values'].extend(latency_min_values)
            results_dict['latency_avg_values'].extend(latency_avg_values)
            results_dict['latency_max_values'].extend(latency_max_values)
            results_dict['latency_95_percent_values'].extend(latency_95_percent_values)
            results_dict['latency_sum_values'].extend(latency_sum_values)

            results_dict['table_size'].extend([
                '100', '1000', '10000', '100000', '1000000',
                '100', '1000', '10000', '100000', '1000000'
            ])

            results_dict['test_type'].extend([
                'read_write', 'read_write', 'read_write', 'read_write', 'read_write',
                'read_only', 'read_only', 'read_only', 'read_only', 'read_only'
            ])
            results_dict['environment'].extend([env_type] * len(queries_read_values))

    @staticmethod
    def write_csv(path, results_dict, headers):
        print(headers)
        print('write csv', path)
        size = len(results_dict[headers[0]])
        data_list = [headers]

        for i in range(size):
            row = []
            for value in headers:
                row.append(results_dict[value][i])
            data_list.append(row)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w') as file:
            writer = csv.writer(file)
            writer.writerows(data_list)

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

    @staticmethod
    def queries_performed(lines, operation):
        queries_lines = list(filter(lambda x: '{}:'.format(operation) in x, lines))
        return list(map(lambda x: re.search(r'([0-9]{0,9})\n', x).group(1), queries_lines))

    @staticmethod
    def latency(lines, operation):
        latency_lines = list(filter(lambda x: '{}:'.format(operation) in x, lines))
        return list(map(lambda x: re.search(r'([0-9]{0,9}\.[0-9]{2})', x).group(1), latency_lines))


rp = ResultParser(files_list, params, params_db)
for p in platforms:
    for tt in test_types:
        rp.generate_csv(p, tt)

print('done')
