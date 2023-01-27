from ansible.plugins.inventory import BaseInventoryPlugin
from ansible.template import Templar

def __init__(self):
    super(BaseInventoryPlugin, self).__init__()

class InventoryModule(BaseInventoryPlugin):
    
    NAME = 'aws_ec2.yaml'

def parse(self, inventory, loader, path):
    self.loader = loader
    self.inventory = inventory
    self.templar = Templar(loader=loader)
    self.path = path("/etc/ansible/aws_ec2.yaml")