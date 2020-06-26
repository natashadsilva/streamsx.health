## Output of various endpoints

WaveForm endpoint

URL = `http://localhost:8014/health/WaveformData/ports/input/0/tuples?partition=patient-102&partition=X100-8`

Sample output: list of observations
            [
            {
                "observations": [
                {
                    "patient_id": "patient-102",
                    "value": -0.055,
                    "readingType": "X100-8",
                    "ts": 72617
                },
                {
                    "patient_id": "patient-102",
                    "value": -0.065,
                    "readingType": "X100-8",
                    "ts": 72625
                }
                ],
                "patient_id": "patient-102",
                "readingType": "X100-8",
                "windowCount": 2837351
            },
            {
                "observations": [
                {
                    "patient_id": "patient-102",
                    "value": -0.635,
                    "readingType": "X100-8",
                    "ts": 72688
                },
                {
                    "patient_id": "patient-102",
                    "value": -0.405,
                    "readingType": "X100-8",
                    "ts": 72695
                },
                {
                    "patient_id": "patient-102",
                    "value": -0.135,
                    "readingType": "X100-8",
                    "ts": 72766
                }
                ],
                "patient_id": "patient-102",
                "readingType": "X100-8",
                "windowCount": 2842352
            }
            ]



Status endpoint: `http://localhost:8014/health/Status/ports/input/0/tuples`
Sample output:        
        [
        {
            "patientMap": {
            "patient-230": {
                "patientId": "patient-230",
                "alert": false,
                "messages": []
            },
            "patient-233": {
                "patientId": "patient-233",
                "alert": false,
                "messages": []
            },
            "patient-112": {
                "patientId": "patient-112",
                "alert": false,
                "messages": []
            },
            "patient-234": {
                "patientId": "patient-234",
                "alert": false,
                "messages": []
            },
            "patient-113": {
                "patientId": "patient-113",
                "alert": false,
                "messages": []
            },
            "patient-231": {
                "patientId": "patient-231",
                "alert": false,
                "messages": []
            },
            "patient-110": {
                "patientId": "patient-110",
                "alert": false,
                "messages": []
            }
            }
        }
        ]




